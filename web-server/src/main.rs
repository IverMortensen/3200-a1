use gethostname::gethostname;
use std::process::exit;
use tiny_http::{Response, Server};

fn main() {
    let server = Server::http("0.0.0.0:0").unwrap();
    let listen_addr = server.server_addr();

    let port = match listen_addr {
        tiny_http::ListenAddr::IP(socket_addr) => socket_addr.port().to_string(),
        tiny_http::ListenAddr::Unix(_) => {
            println!("Server running on Unix socket.");
            exit(1);
        }
    };

    let host = gethostname()
        .to_string_lossy()
        .split(".")
        .next()
        .unwrap_or("unknown")
        .to_string();

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
