use gdnative::*;
use std::collections::{HashMap, HashSet};
use std::mem::swap;
use std::sync::mpsc::{self, TryRecvError};
use std::thread::{self, JoinHandle};
use std::time::{Duration, Instant};

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
    fn set_tick_rate(&self, _owner: Reference, tick_rate: f32) {
        self.manager.set_tick_rate(tick_rate);
    }

    #[export]
    fn step(&self, _owner: Reference) {
        self.manager.step();
    }

    #[export]
    fn start(&self, _owner: Reference) {
        self.manager.start();
    }

    #[export]
    fn stop(&self, _owner: Reference) {
        self.manager.stop();
    }
}

enum Command {
    TickRate(f32),
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

    fn set_tick_rate(&self, tick_rate: f32) {
        self.command_tx.send(Command::TickRate(tick_rate)).ok();
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
    tick_period: Duration,
    next_tick: Option<Instant>,
    state: State,
    current: UpdateBuffer,
    next: UpdateBuffer,
}

impl Runner {
    fn new(command_rx: mpsc::Receiver<Command>) -> Runner {
        Runner {
            command_rx,
            tick_period: Duration::from_millis(10),
            next_tick: None,
            state: State::new(),
            current: UpdateBuffer::new(),
            next: UpdateBuffer::new(),
        }
    }

    fn is_running(&self) -> bool {
        self.next_tick.is_some()
    }

    fn step(&mut self) {
        self.state.apply(&self.current, &mut self.next);
        self.current.clear();
        swap(&mut self.current, &mut self.next);
    }

    fn run(&mut self) {
        'main: loop {
            if let Some(next_tick) = self.next_tick {
                if let Some(remaining_time) = next_tick.checked_duration_since(Instant::now()) {
                    thread::sleep(remaining_time);
                }
                self.step();
                self.next_tick = Some(next_tick + self.tick_period);
            }
            'recv: loop {
                let command = if self.is_running() {
                    self.command_rx.try_recv()
                } else {
                    self.command_rx.recv().map_err(Into::into)
                };
                match command {
                    Ok(Command::TickRate(tick_rate)) => {
                        self.tick_period = Duration::from_secs(1).div_f32(tick_rate);
                    }
                    Ok(Command::Step) => {
                        self.step();
                    }
                    Ok(Command::Start) => {
                        self.next_tick = Some(Instant::now());
                    }
                    Ok(Command::Stop) => {
                        self.next_tick = None;
                    }
                    Ok(Command::Exit) | Err(TryRecvError::Disconnected) => {
                        break 'main;
                    }
                    Err(TryRecvError::Empty) => {
                        break 'recv;
                    }
                }
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
