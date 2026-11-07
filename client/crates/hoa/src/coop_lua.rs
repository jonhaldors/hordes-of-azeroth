use std::io::{Read, Write};
use std::net::{SocketAddr, TcpStream};
use std::collections::HashMap;
use std::sync::{Mutex, PoisonError};
use std::time::{Duration, Instant};

use benilla_mlua::{Lua, Result as LuaResult};
use benilla_protocol::{current_gate, set_gate, Gate};

const DEFAULT_AGENT_PORT: u16 = 3727;
const CONNECT_TIMEOUT: Duration = Duration::from_millis(300);
const ANSWER_TIMEOUT: Duration = Duration::from_millis(1500);
const ANSWER_LIMIT: u64 = 256 * 1024;
const UNCOLLECTED_CALL_LIFETIME: Duration = Duration::from_secs(60);

static JOINED_LOGIN: Mutex<Option<(String, String)>> = Mutex::new(None);
type BackgroundCall = (Instant, Option<Result<String, String>>);

static BACKGROUND_CALLS: Mutex<Option<HashMap<u32, BackgroundCall>>> = Mutex::new(None);
static NEXT_CALL_ID: Mutex<u32> = Mutex::new(0);

fn start_background_call(method: String, path: String, body: String) -> u32 {
    let id = {
        let mut next = NEXT_CALL_ID.lock().unwrap_or_else(PoisonError::into_inner);
        *next = next.wrapping_add(1);
        *next
    };
    {
        let mut guard = BACKGROUND_CALLS.lock().unwrap_or_else(PoisonError::into_inner);
        let calls = guard.get_or_insert_with(HashMap::new);
        calls.retain(|_, (started, _)| started.elapsed() < UNCOLLECTED_CALL_LIFETIME);
        calls.insert(id, (Instant::now(), None));
    }
    std::thread::spawn(move || {
        let answer = call_agent(&method, &path, &body);
        if let Some(calls) = BACKGROUND_CALLS.lock().unwrap_or_else(PoisonError::into_inner).as_mut() {
            if let Some((_, slot)) = calls.get_mut(&id) {
                *slot = Some(answer);
            }
        }
    });
    id
}

fn take_background_call(id: u32) -> Option<Result<String, String>> {
    let mut guard = BACKGROUND_CALLS.lock().unwrap_or_else(PoisonError::into_inner);
    let calls = guard.as_mut()?;
    match calls.get(&id) {
        Some((_, Some(_))) => calls.remove(&id).and_then(|(_, answer)| answer),
        Some((_, None)) => None,
        None => Some(Err("Unknown call.".to_string())),
    }
}

pub fn register_coop_api(lua: &Lua) -> LuaResult<()> {
    let globals = lua.globals();
    globals.set(
        "HoaCoop_Call",
        lua.create_function(|_, (method, path, body): (String, String, Option<String>)| {
            Ok(match call_agent(&method, &path, body.as_deref().unwrap_or("")) {
                Ok(answer) => (Some(answer), None),
                Err(error) => (None, Some(error)),
            })
        })?,
    )?;
    globals.set(
        "HoaCoop_Start",
        lua.create_function(|_, (method, path, body): (String, String, Option<String>)| {
            Ok(start_background_call(method, path, body.unwrap_or_default()))
        })?,
    )?;
    globals.set(
        "HoaCoop_Take",
        lua.create_function(|_, id: u32| {
            Ok(match take_background_call(id) {
                None => (true, None, None),
                Some(Ok(answer)) => (false, Some(answer), None),
                Some(Err(error)) => (false, None, Some(error)),
            })
        })?,
    )?;
    globals.set(
        "HoaCoop_SetGate",
        lua.create_function(
            |_, (address, token, user, password, character): (Option<String>, Option<String>, Option<String>, Option<String>, Option<String>)| {
                let joined = match (address, token, user, password) {
                    (Some(address), Some(token), Some(user), Some(password))
                        if !address.is_empty() && !token.is_empty() =>
                    {
                        Some((Gate { address, token }, user, password))
                    }
                    _ => None,
                };
                set_gate(joined.as_ref().map(|(gate, _, _)| gate.clone()));
                benilla_app::set_character_alias(joined.as_ref().and(character));
                *JOINED_LOGIN.lock().unwrap_or_else(PoisonError::into_inner) =
                    joined.map(|(_, user, password)| (user, password));
                Ok(())
            },
        )?,
    )?;
    globals.set(
        "HoaCoop_GetGate",
        lua.create_function(|_, ()| {
            let login = JOINED_LOGIN.lock().unwrap_or_else(PoisonError::into_inner).clone();
            Ok(match (current_gate(), login) {
                (Some(gate), Some((user, password))) => (Some(gate.address), Some(user), Some(password)),
                _ => (None, None, None),
            })
        })?,
    )?;
    Ok(())
}

fn agent_port() -> u16 {
    std::env::var("HOA_COOP_PORT")
        .ok()
        .and_then(|port| port.parse().ok())
        .unwrap_or(DEFAULT_AGENT_PORT)
}

fn call_agent(method: &str, path: &str, body: &str) -> Result<String, String> {
    let address = SocketAddr::from(([127, 0, 0, 1], agent_port()));
    let mut stream = TcpStream::connect_timeout(&address, CONNECT_TIMEOUT)
        .map_err(|_| "The launcher isn't running.".to_string())?;
    stream
        .set_read_timeout(Some(ANSWER_TIMEOUT))
        .map_err(|e| e.to_string())?;
    let request = format!(
        "{method} {path} HTTP/1.0\r\nHost: 127.0.0.1\r\nContent-Type: text/plain\r\nContent-Length: {}\r\n\r\n{body}",
        body.len()
    );
    stream
        .write_all(request.as_bytes())
        .map_err(|e| e.to_string())?;
    let mut raw = Vec::new();
    stream
        .take(ANSWER_LIMIT)
        .read_to_end(&mut raw)
        .map_err(|_| "The launcher didn't answer.".to_string())?;
    let text = String::from_utf8_lossy(&raw);
    let (head, content) = text
        .split_once("\r\n\r\n")
        .ok_or_else(|| "The launcher sent a broken answer.".to_string())?;
    let ok = head
        .lines()
        .next()
        .is_some_and(|status| status.split_whitespace().nth(1) == Some("200"));
    if ok {
        Ok(content.to_string())
    } else {
        Err(content.trim().to_string())
    }
}
