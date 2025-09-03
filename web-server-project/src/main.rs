use std::{env, process::exit};
use tiny_http::{Response, Server};

fn main() {
    let args: Vec<String> = env::args().collect();
    if args.len() != 3 {
        eprintln!("Usage: {} <host> <port>", args[0]);
        exit(1);
    }

    let host = &args[1];
    let port = &args[2];
    let address = format!("0.0.0.0:{}", port);

    let server = match Server::http(&address) {
        Ok(server) => {
            println!("Server running on: {}", &address);
            server
        }
        Err(e) => {
            eprintln!("Failed to bind to {}: {}", address, e);
            exit(98);
        }
    };

    println!("Host:port {}:{}", host, port);

    for request in server.incoming_requests() {
        println!(
            "received request! method: {:?}, url: {:?}, headers: {:?}",
            request.method(),
            request.url(),
            request.headers()
        );

        if request.url() == "/helloworld" {
            let response = Response::from_string(format!("{}:{}", host, port));
            let _ = request.respond(response);
        } else {
            let response = Response::from_string("404");
            let _ = request.respond(response);
        }
    }
}
