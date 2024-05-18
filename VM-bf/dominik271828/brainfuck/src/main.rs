use std::env;
use std::fs;
use std::process::exit;
const TAPE_SIZE: usize = 30_000;
struct BrainFuckInterpreter {
    // The whole memory is an array of 30,000 bytes
    memory: [u8; TAPE_SIZE],
    // Memory pointer, points to the current cell
    mp: usize, 
    // Program counter, points to the index of the current instruction 
    pc: usize, 
}
impl BrainFuckInterpreter {
    pub fn new() -> Self {
        Self {
            memory: [0; TAPE_SIZE],
            mp: 0,
            pc: 0, 
        }
    }

    pub fn process_program(mut self, program: &str) {
        let mut c = 0;
        while self.pc < program.len() {
            let ch = program.chars().nth(self.pc).unwrap();
            // println!("{}", ch);
            match ch {
                '>' => {
                    self.mp = self.mp.overflowing_add(1).0;
                }
                '<' => {
                    self.mp = self.mp.overflowing_sub(1).0;
                }
                '+' => {
                    self.memory[self.mp] += 1;
                    // println!("{}", self.memory[self.mp]);
                }
                '-' => {
                    self.memory[self.mp] -= 1;
                }
                ',' => {
                    let mut input = String::new();
                    std::io::stdin().read_line(&mut input).unwrap();
                    let i: u8 = input.as_bytes()[0];
                    self.memory[self.mp] = i;
                    // if i == 10 {
                    //     self.memory[self.mp] = 0;
                    // }
                }
                '.' => {
                    // TODO: instead of printing the number, print ASCII?
                    print!("{}", char::from_u32(self.memory[self.mp] as u32).unwrap());
                    //print!("{}", self.memory[self.mp]);

                }
                '[' => {
                    // if zero, then jump to the end of the loop
                    // and set the pc to the end( ']' ) char
                    if self.memory[self.mp] == 0 {
                        self.pc += 1;
                        while c > 0 || program.chars().nth(self.pc).unwrap() != ']' {
                            if program.chars().nth(self.pc).unwrap() == '[' {
                                c += 1;
                            }
                            else if program.chars().nth(self.pc).unwrap() == ']' {
                                c -= 1;
                            }
                            self.pc += 1;
                        }
                    }
                }
                ']' => {
                    if self.memory[self.mp] != 0 {
                        self.pc -= 1;
                        while c > 0 || program.chars().nth(self.pc).unwrap() != '[' {
                            if program.chars().nth(self.pc).unwrap() == ']' {
                                c += 1;
                            }
                            else if program.chars().nth(self.pc).unwrap() == '[' {
                                c -= 1;
                            }
                            self.pc -= 1;
                        }
                    }

                }

                _ => {
                        let l = ch.to_string();
                        eprintln!("Unknown instruction: {:?}", l.as_bytes());
                        exit(0x1);
                }
            }
            self.pc += 1;
        }
    }
}

fn main() {
    let interpreter = BrainFuckInterpreter::new();
    let args: Vec<String> = env::args().collect();
    let program = fs::read_to_string(args[1].as_str()).unwrap().replace("\n", "").replace(" ", "");
    interpreter.process_program(program.as_str());
}
