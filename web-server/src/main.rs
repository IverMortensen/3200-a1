use std::process::Command;
use tiny_http::{Response, Server};

fn run_script(script_path: &str) -> Result<String, String> {
    let output = Command::new("sh")
        .arg(script_path)
        .output()
        .map_err(|e| format!("Failed to run script {}", e))?;

    if output.status.success() {
        Ok(String::from_utf8_lossy(&output.stdout).to_string())
    } else {
        let stderr = String::from_utf8_lossy(&output.stderr).to_string();
        Err(format!("Script failed {}", stderr))
    }
}

fn main() {
    let server = Server::http("0.0.0.0:0").unwrap();
    let listen_addr = server.server_addr();

    let port = match listen_addr {
        tiny_http::ListenAddr::IP(socket_addr) => {
            println!("Server running on port: {}", socket_addr.port());
            socket_addr.port().to_string()
        }
        tiny_http::ListenAddr::Unix(_) => {
            println!("Server running on Unix socket");
            format!("Unix")
        }
    };

    let result = run_script("/share/ifi/node-info.sh");
    let host = match result {
        Ok(output) => output.trim().split(",").next().unwrap_or("").to_string(),
        Err(error) => {
            eprintln!("Error: {}", error);
            format!("ERROR")
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
