use std::error::Error;

fn get_byte_array(ptr: &u8, l:u64) -> Result<&[u8], Box<dyn Error>> {
    unsafe {
        let rawslice = std::slice::from_raw_parts(ptr, l as usize);
        Ok(rawslice)
    }
}

fn decode_helper(buf: Option<&image::RgbImage>) -> Option<(u32, u32)> {
    let dims = buf?.dimensions();
    // hey
    Some(dims)
}

fn _decode(ptr: &u8, l: u64) -> Result<Vec<u8>, Box<dyn Error>> {
    let a = get_byte_array(ptr, l)?;
    let result = image::load_from_memory(a)?;
    let buf = result.as_rgb8();
    let decoded = decode_helper(buf).unwrap_or((0,0));

    println!("rust -> {:?} <- rust", decoded);

    let vals = vec![decoded.0 as u8, decoded.1 as u8];

    Ok(vals)
}

#[no_mangle]
pub extern fn decode(ptr: &u8, l: u64) -> Vec<u8> {
    match _decode(ptr, l) {
        Ok(val) => val,
        Err(_) => vec![0,0],
    }
}

#[no_mangle]
pub extern fn hello() {
    println!("Hey there!: Curr dir is {}", std::env::current_dir().unwrap().display());
}
