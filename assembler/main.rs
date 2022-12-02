use clap::Parser;
use anyhow::Result;
use compile::to_blob;
use parsing::parse_to_ast;
use std::{path::PathBuf, process::exit};

mod ast;
mod compile;
mod parsing;

#[derive(Parser)]
struct Cli {
    #[arg(short, long)]
    output: Option<PathBuf>,
    path: PathBuf,
}

fn main() -> Result<()> {
    let (path, output) = {
        let args = Cli::parse();
        let path = match args.path.canonicalize() {
            Ok(p) => p,
            Err(e) => {
                eprintln!("Error: {}", e);
                exit(1);
            }
        };
        let output = match args.output {
            Some(p) => match p.canonicalize() {
                Ok(p) => p,
                Err(e) => {
                    eprintln!("Error: {}", e);
                    exit(1);
                }
            },
            None => path.file_stem().unwrap().into(),
        };
        (path, output)
    };

    let ast = parse_to_ast(&path)?;
    to_blob(&ast, &output)?;
    Ok(())
}
