use gdnative::*;
use std::collections::{HashMap, HashSet};
use std::mem::swap;
use std::sync::mpsc::{self, TryRecvError};
use std::thread::{self, JoinHandle};

#[derive(NativeClass)]
#[inherit(Reference)]
struct Simulation {
    manager: Manager,
}

#[methods]
impl Simulation {
    fn _init(_owner: Reference) -> Self {
        Simulation {
            manager: Manager::new(),
        }
    }

    #[export]
    fn step(&mut self, _owner: Reference) {
        self.manager.step();
    }

    #[export]
    fn start(&mut self, _owner: Reference) {
        self.manager.start();
    }

    #[export]
    fn stop(&mut self, _owner: Reference) {
        self.manager.stop();
    }
}

enum Command {
    Step,
    Start,
    Stop,
    Exit,
}

struct Manager {
    command_tx: mpsc::Sender<Command>,
    _thread: JoinHandle<()>,
}

impl Manager {
    fn new() -> Manager {
        let (command_tx, command_rx) = mpsc::channel();
        Manager {
            command_tx,
            _thread: thread::spawn(move || Runner::new(command_rx).run()),
        }
    }

    fn step(&self) {
        self.command_tx.send(Command::Step).ok();
    }

    fn start(&self) {
        self.command_tx.send(Command::Start).ok();
    }

    fn stop(&self) {
        self.command_tx.send(Command::Stop).ok();
    }
}

struct Runner {
    command_rx: mpsc::Receiver<Command>,
    running: bool,
    state: State,
    current: UpdateBuffer,
    next: UpdateBuffer,
}

impl Runner {
    fn new(command_rx: mpsc::Receiver<Command>) -> Runner {
        Runner {
            command_rx,
            running: false,
            state: State::new(),
            current: UpdateBuffer::new(),
            next: UpdateBuffer::new(),
        }
    }

    fn step(&mut self) {
        self.state.apply(&self.current, &mut self.next);
        self.current.clear();
        swap(&mut self.current, &mut self.next);
    }

    fn run(&mut self) {
        loop {
            let command = if self.running {
                self.command_rx.try_recv()
            } else {
                self.command_rx.recv().map_err(Into::into)
            };
            match command {
                Ok(Command::Step) => {
                    self.step();
                }
                Ok(Command::Start) => {
                    self.running = true;
                }
                Ok(Command::Stop) => {
                    self.running = false;
                }
                Ok(Command::Exit) | Err(TryRecvError::Disconnected) => {
                    break;
                }
                Err(TryRecvError::Empty) => {}
            }
            if self.running {
                self.step();
                //TODO implement tickrate
            }
        }
    }
}

struct State {
    wires: Vec<Wire>,
}

impl State {
    fn new() -> State {
        State { wires: Vec::new() }
    }

    fn apply(&mut self, current: &UpdateBuffer, next: &mut UpdateBuffer) {
        for (&wire_id, &delta) in &current.updates {
            let wire = &mut self.wires[wire_id];
            let old_state = wire.is_on();
            wire.input_count += delta;
            let new_state = wire.is_on();

            if new_state != old_state {
                let (to_set, to_reset) = match new_state {
                    true => (&wire.blotted, &wire.inverted),
                    false => (&wire.inverted, &wire.blotted),
                };
                for &sub_id in to_set {
                    next.set(sub_id)
                }
                for &sub_id in to_reset {
                    next.reset(sub_id)
                }
            }
        }
    }
}

struct Wire {
    input_count: isize,
    blotted: HashSet<usize>,
    inverted: HashSet<usize>,
}

impl Wire {
    fn is_on(&self) -> bool {
        self.input_count > 0
    }
}

struct UpdateBuffer {
    updates: HashMap<usize, isize>,
}

impl UpdateBuffer {
    fn new() -> UpdateBuffer {
        UpdateBuffer {
            updates: HashMap::new(),
        }
    }

    fn clear(&mut self) {
        self.updates.clear();
    }

    fn set(&mut self, id: usize) {
        *self.updates.entry(id).or_insert(0) += 1;
    }

    fn reset(&mut self, id: usize) {
        *self.updates.entry(id).or_insert(0) -= 1;
    }
}

fn init(handle: gdnative::init::InitHandle) {
    handle.add_class::<Simulation>();
}

godot_gdnative_init!();
godot_nativescript_init!(init);
godot_gdnative_terminate!();
