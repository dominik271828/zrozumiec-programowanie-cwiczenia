use std::env;
use std::fs;
use R::*;
use OP::*;
const TAPE_LEN: usize = 1000;
enum R {
    R0 = 0x00, 
    R1 = 0x01,
    R2 = 0x02,
    R3 = 0x03,
    R4 = 0x04,
    R5 = 0x05,
    R6 = 0x06,
    R7 = 0x07,
    R8 = 0x08,
    R9 = 0x09,
    R10 = 0x0A,
    R11 = 0x0B,
    R12 = 0x0C,
    R13 = 0x0D,
    SP = 0x0E,
    IP = 0x0F,
}
enum OP {
    // First group - memory access instructions
    VMOV = 0x00, 
    VSET = 0x01,
    VLDB = 0x04,
    VSTB = 0x05,
    // Second group - arithmetic operations instructions
    VADD = 0x10,
    VSUB = 0x11, 
    // Third group - conditional jumps and compare instructions
    VCMP = 0x20, 
    VJZ = 0x21,
    // Fifth group - unconditinal jumps
    VJMP = 0x40, 
    // Sixth group - additional steering instructions
    VOUTB = 0xF2, 
    VINB = 0xF3, 
    VOFF = 0xFF,  
}
fn write_opcode(
    binary: &mut Vec<u8>,
    op: OP,
    rdst: Option<R>,
    rsrc: Option<R>,
    imm: Option<u32>,
    no_bytes: Option<u8>,
) {
    binary.push(op as u8);
    if let Some(val) = rdst {
        binary.push(val as u8);
    }
    if let Some(val) = rsrc {
        binary.push(val as u8);
    }
    if let Some(imm) = imm {
        let no_bytes = no_bytes.unwrap();
        for i in 0..no_bytes {
            binary.push(((imm >> (i * 8)) & 0xFF) as u8);
        }
    }
}
// r10 stores the beginning of the tape 
// r0 stores the current tape segment we're at
// r1 is always 1, for arithmetic purposes
// r11 is always 0, if we change that, it is an error
fn main() {
    let args: Vec<String> = env::args().collect();
    let mut binary: Vec<u8> = vec![];
    let bf_chars: Vec<char> = vec!['.', ',', '-', '+', '<', '>', '[', ']'];
    if args.len() < 3 {
        println!("Usage: cargo run -- input_file output_file");
        std::process::exit(1);
    }
    let program: Vec<u8> = fs::read(&args[1]).expect("File read err");
    let mut brackets: Vec<usize> = vec![];
    // Filter from the input only the valid brainfuck chars
    let program: Vec<u8> = program.into_iter().filter(|x| bf_chars.contains(&(*x as char))).collect();
    write_opcode(&mut binary, VSET, Some(R10), None, Some(0), Some(4)); // Insert the correct address at the end of the program
    write_opcode(&mut binary, VMOV, Some(R0), Some(R10), None, None); // VMOV R0, R10
    write_opcode(&mut binary, VSET, Some(R1), None, Some(1), Some(4)); // VSET R1, 1
    write_opcode(&mut binary, VSET, Some(R11), None, Some(0), Some(4)); // VSET R11, 0
    for instr in &program {
        match *instr as char {
            '+' => {
                // VLDB R2, R0
                write_opcode(&mut binary, VLDB, Some(R2), Some(R0), None, None);
                // VADD R2, R1
                write_opcode(&mut binary, VADD, Some(R2), Some(R1), None, None);
                // VSTB R0, R2
                write_opcode(&mut binary, VSTB, Some(R0), Some(R2), None, None);
            },
            '-' => {
                // VLDB R2, R0
                write_opcode(&mut binary, VLDB, Some(R2), Some(R0), None, None);
                // VSUB R2, R1
                write_opcode(&mut binary, VSUB, Some(R2), Some(R1), None, None);
                // VSTB R0, R2
                write_opcode(&mut binary, VSTB, Some(R0), Some(R2), None, None);
            },
            '>' => { // As of now, no checking for out of bounds tape access
                // VADD R0, R1
                write_opcode(&mut binary, VADD, Some(R0), Some(R1), None, None);
            },
            '<' => {
                // SUB R0, R1
                write_opcode(&mut binary, VSUB, Some(R0), Some(R1), None, None);
            },
            '.' => {
                // VLDB R2, R0
                write_opcode(&mut binary, VLDB, Some(R2), Some(R0), None, None);
                // VOUTB 0x20, R2
                write_opcode(&mut binary, VOUTB, Some(R2), None, Some(0x20), Some(1));
            },
            ',' => {
                // VINB 0x20, R2 
                write_opcode(&mut binary, VINB, Some(R2), None, Some(0x20), Some(1));
                // VSTB R0, R2
                write_opcode(&mut binary, VSTB, Some(R0), Some(R2), None, None);
            },
            // The main idea for brackets is:
            // On '[' when 0 on the current cell, jump to matching ']', when parsing always write
            // VJZ 0, and we go back to there once we encounter a ']'
            // On ']' always jump to the matching '['
            '[' => {
                // Push the address (idx) of the bracket
                brackets.push(binary.len());
                // VLDB R2, R0
                write_opcode(&mut binary, VLDB, Some(R2), Some(R0), None, None);
                // VCMP R2, R11
                write_opcode(&mut binary, VCMP, Some(R2), Some(R11), None, None);
                // VJZ 0
                write_opcode(&mut binary, VJZ, None, None, Some(0), Some(2));

            },
            ']' => {
                let target_address = brackets.pop().unwrap_or_else(| | {eprintln!("brack err"); panic!();});
                let jmp_address = binary.len();
                let imm16 = ((target_address + 2_usize.pow(16) - (jmp_address + 3)) ) as u32;
                // VJMP [address of matching ']']
                write_opcode(&mut binary, VJMP, None, None, Some(imm16), Some(2));
                // Rewrite the target address
                let bytes: u16 = ((jmp_address + 3) - (target_address + 6 + 3)) as u16;
                binary[target_address + 7] = (bytes & 0x00FF) as u8;
                binary[target_address + 8] = (bytes >> 8) as u8;
            }
            _ => panic!("Unknown instruction"), 
        }
    }
    // VOFF
    write_opcode(&mut binary, VOFF, None, None, None, None);
    // Set r10 to the beginning of the tape
    let len: u32 = binary.len() as u32;
    // Add 100 bytes to the binary
    binary[2] = (len & 0x000000FF) as u8;
    binary[3] = ((len & 0x0000FF00) >> 8) as u8;
    binary[4] = ((len & 0x00FF0000) >> 16) as u8;
    binary[5] = ((len & 0xFF000000) >> 24) as u8;
    binary.extend_from_slice(&[0; TAPE_LEN]);

    fs::write(&args[2], &binary).expect("Write file err");
}
