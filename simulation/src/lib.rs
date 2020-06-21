use gdnative::*;
use std::collections::{HashMap, HashSet};
use std::mem::swap;
use std::sync::mpsc::{self, TryRecvError};
use std::sync::{Arc, Mutex};
use std::thread::{self, JoinHandle};
use std::time::{Duration, Instant};

godot_gdnative_init!();
godot_nativescript_init!(init);
godot_gdnative_terminate!();

fn init(handle: gdnative::init::InitHandle) {
    handle.add_class::<Simulation>();
}

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
    fn get_state(&self, _owner: Reference) -> Variant {
        self.manager.state().to_variant()
    }

    #[export]
    fn set_tick_rate(&mut self, _owner: Reference, tick_rate: f32) {
        self.manager.send(Command::TickRate { tick_rate });
    }

    #[export]
    fn set(&mut self, _owner: Reference, id: usize) {
        self.manager.send(Command::Set { id });
    }

    #[export]
    fn reset(&mut self, _owner: Reference, id: usize) {
        self.manager.send(Command::Reset { id });
    }

    #[export]
    fn place_blotter(&mut self, _owner: Reference, in_id: usize, out_id: usize) {
        self.manager.send(Command::PlaceBlotter { in_id, out_id });
    }

    #[export]
    fn remove_blotter(&mut self, _owner: Reference, in_id: usize, out_id: usize) {
        self.manager.send(Command::RemoveBlotter { in_id, out_id });
    }

    #[export]
    fn place_inverter(&mut self, _owner: Reference, in_id: usize, out_id: usize) {
        self.manager.send(Command::PlaceInverter { in_id, out_id });
    }

    #[export]
    fn remove_inverter(&mut self, _owner: Reference, in_id: usize, out_id: usize) {
        self.manager.send(Command::RemoveInverter { in_id, out_id });
    }

    #[export]
    fn step(&mut self, _owner: Reference) {
        self.manager.send(Command::Step);
    }

    #[export]
    fn start(&mut self, _owner: Reference) {
        self.manager.send(Command::Start);
    }

    #[export]
    fn stop(&mut self, _owner: Reference) {
        self.manager.send(Command::Stop);
    }

    #[export]
    fn start_atomic(&mut self, _owner: Reference) {
        self.manager.start_atomic();
    }

    #[export]
    fn finish_atomic(&mut self, _owner: Reference) {
        self.manager.finish_atomic();
    }
}

enum Command {
    TickRate { tick_rate: f32 },
    Set { id: usize },
    Reset { id: usize },
    PlaceBlotter { in_id: usize, out_id: usize },
    RemoveBlotter { in_id: usize, out_id: usize },
    PlaceInverter { in_id: usize, out_id: usize },
    RemoveInverter { in_id: usize, out_id: usize },
    Step,
    Start,
    Stop,
    Atomic(Vec<Command>),
}

struct Manager {
    command_tx: mpsc::Sender<Command>,
    output: Arc<Mutex<Option<Vec<bool>>>>,
    _thread: JoinHandle<()>,
    atomic_buffer: Option<Vec<Command>>,
    atomic_depth: usize,
}

impl Manager {
    fn new() -> Manager {
        let (command_tx, command_rx) = mpsc::channel();
        let output = Arc::new(Mutex::new(None));
        Manager {
            command_tx,
            output: Arc::clone(&output),
            _thread: thread::spawn(move || ThreadRunner::new(command_rx, output).run()),
            atomic_buffer: None,
            atomic_depth: 0,
        }
    }

    fn state(&self) -> Option<Vec<bool>> {
        self.output.lock().unwrap().take()
    }

    fn send(&mut self, command: Command) {
        if let Some(atomic_buffer) = self.atomic_buffer.as_mut() {
            atomic_buffer.push(command);
        } else {
            self.command_tx.send(command).ok();
        }
    }

    fn start_atomic(&mut self) {
        if self.atomic_buffer.is_none() {
            self.atomic_buffer = Some(Vec::new());
        } else {
            self.atomic_depth += 1;
        }
    }

    fn finish_atomic(&mut self) {
        if self.atomic_depth > 0 {
            self.atomic_depth -= 1;
        } else if let Some(atomic_buffer) = self.atomic_buffer.take() {
            if !atomic_buffer.is_empty() {
                self.send(Command::Atomic(atomic_buffer));
            }
        }
    }
}

struct ThreadRunner {
    command_rx: mpsc::Receiver<Command>,
    output: Arc<Mutex<Option<Vec<bool>>>>,
    tick_period: Duration,
    next_tick: Option<Instant>,
    runner: Runner,
}

impl ThreadRunner {
    fn new(
        command_rx: mpsc::Receiver<Command>,
        output: Arc<Mutex<Option<Vec<bool>>>>,
    ) -> ThreadRunner {
        ThreadRunner {
            command_rx,
            output,
            tick_period: Duration::from_millis(10),
            next_tick: None,
            runner: Runner::new(),
        }
    }

    fn step(&mut self) {
        self.runner.step();
        let output = self.runner.state.wires.iter().map(Wire::is_on).collect();
        *self.output.lock().unwrap() = Some(output);
    }

    fn is_running(&self) -> bool {
        self.next_tick.is_some()
    }

    fn handle(&mut self, command: Command) {
        match command {
            Command::TickRate { tick_rate } => {
                self.tick_period = Duration::from_secs(1).div_f32(tick_rate);
            }
            Command::Set { id } => {
                self.runner.set(id);
            }
            Command::Reset { id } => {
                self.runner.reset(id);
            }
            Command::PlaceBlotter { in_id, out_id } => {
                self.runner.place_blotter(in_id, out_id);
            }
            Command::RemoveBlotter { in_id, out_id } => {
                self.runner.remove_blotter(in_id, out_id);
            }
            Command::PlaceInverter { in_id, out_id } => {
                self.runner.place_inverter(in_id, out_id);
            }
            Command::RemoveInverter { in_id, out_id } => {
                self.runner.remove_inverter(in_id, out_id);
            }
            Command::Step => {
                self.step();
            }
            Command::Start => {
                self.next_tick = Some(Instant::now());
            }
            Command::Stop => {
                self.next_tick = None;
            }
            Command::Atomic(commands) => {
                for command in commands {
                    self.handle(command);
                }
            }
        }
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
                    Ok(command) => self.handle(command),
                    Err(TryRecvError::Disconnected) => {
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

struct Runner {
    state: State,
    current: UpdateBuffer,
    next: UpdateBuffer,
}

impl Runner {
    fn new() -> Runner {
        Runner {
            state: State::new(),
            current: UpdateBuffer::new(),
            next: UpdateBuffer::new(),
        }
    }

    fn set(&mut self, id: usize) {
        self.current.set(id);
    }

    fn reset(&mut self, id: usize) {
        self.current.reset(id);
    }

    fn place_blotter(&mut self, in_id: usize, out_id: usize) {
        let input = self.state.wire(in_id);
        if input.blotted.insert(out_id) && input.is_on() {
            self.current.set(out_id);
        }
    }

    fn remove_blotter(&mut self, in_id: usize, out_id: usize) {
        let input = self.state.wire(in_id);
        if input.blotted.remove(&out_id) && input.is_on() {
            self.current.reset(out_id);
        }
    }

    fn place_inverter(&mut self, in_id: usize, out_id: usize) {
        let input = self.state.wire(in_id);
        if input.inverted.insert(out_id) && !input.is_on() {
            self.current.set(out_id);
        }
    }

    fn remove_inverter(&mut self, in_id: usize, out_id: usize) {
        let input = self.state.wire(in_id);
        if input.inverted.remove(&out_id) && !input.is_on() {
            self.current.reset(out_id);
        }
    }

    fn step(&mut self) {
        self.state.apply(&self.current, &mut self.next);
        self.current.clear();
        swap(&mut self.current, &mut self.next);
    }
}

struct State {
    wires: Vec<Wire>,
}

impl State {
    fn new() -> State {
        State { wires: Vec::new() }
    }

    fn wire(&mut self, id: usize) -> &mut Wire {
        let min_len = id + 1;
        if self.wires.len() < min_len {
            self.wires.resize_with(min_len, Default::default);
        }
        &mut self.wires[id]
    }

    fn apply(&mut self, current: &UpdateBuffer, next: &mut UpdateBuffer) {
        for (&wire_id, &delta) in &current.updates {
            let wire = self.wire(wire_id);
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

#[derive(Default)]
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

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn inverter_loop() {
        let mut runner = Runner::new();
        runner.place_inverter(0, 0);
        let mut wire0 = false;
        for _ in 0..100 {
            runner.step();
            wire0 = !wire0;
            assert_eq!(runner.state.wire(0).is_on(), wire0);
        }
    }

    #[test]
    fn blotter_loop() {
        let mut runner = Runner::new();
        runner.place_blotter(0, 1);
        runner.place_blotter(1, 0);
        runner.set(0);
        runner.step();
        runner.reset(0);

        let mut wire0 = true;
        let mut wire1 = false;
        for _ in 0..100 {
            runner.step();
            wire0 = !wire0;
            wire1 = !wire1;
            assert_eq!(runner.state.wire(0).is_on(), wire0);
            assert_eq!(runner.state.wire(1).is_on(), wire1);
        }
    }

    #[test]
    fn rs_latch() {
        let mut runner = Runner::new();
        runner.place_inverter(0, 1);
        runner.step();
        runner.place_inverter(1, 0);
        runner.step();
        let mut wire0 = false;
        let mut wire1 = true;

        for _ in 0..100 {
            runner.step();
            assert_eq!(runner.state.wire(0).is_on(), wire0);
            assert_eq!(runner.state.wire(1).is_on(), wire1);
        }

        runner.set(0);
        runner.step();
        runner.step();
        runner.reset(0);
        runner.step();
        wire0 = true;
        wire1 = false;

        for _ in 0..100 {
            runner.step();
            assert_eq!(runner.state.wire(0).is_on(), wire0);
            assert_eq!(runner.state.wire(1).is_on(), wire1);
        }
    }
}
