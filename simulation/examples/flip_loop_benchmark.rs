use simulation::{Command, ThreadRunner};
use std::thread;
use std::time::{Duration, Instant};

fn main() {
    let mut runner = ThreadRunner::new();
    runner.send(Command::PlaceFlip {
        in_id: 0,
        out_id: 0,
    });
    runner.send(Command::TickRate {
        tick_rate: f32::INFINITY,
    });

    let start = Instant::now();
    runner.send(Command::Start);

    thread::sleep(Duration::from_secs(10));

    let end = Instant::now();
    let tick_count = runner.tick_count();
    runner.send(Command::Stop);

    let elapsed = (end - start).as_secs_f32();
    println!("Time elapsed: {}s", elapsed);
    println!("Ticks processed: {}", tick_count);
    println!("TPS: {}", tick_count as f32 / elapsed);
}
