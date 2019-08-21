//use image::GenericImageView;
use std::error::Error;

fn get_byte_array(ptr: &u8, l:u64) -> Result<Vec<u8>, Box<dyn Error>> {
    unsafe {
        let rawslice = std::slice::from_raw_parts(ptr, l as usize);
        Ok(rawslice.to_vec())
    }
}

//fn decode_helper(buf: Option<&image::RgbImage>) -> Option<(u32, u32)> {
//    let dims = buf?.dimensions();
//    Some(dims)
//}

fn _decode(ptr: &u8, l: u64) -> Result<Vec<u8>, Box<dyn Error>> {
    println!("In _decode");
    let a = get_byte_array(ptr, l)?;
    let _result = image::load_from_memory(a)?;
    // let result = _result.unwrap();
    // println!("Loaded from bytes");
    // let buf = result.as_rgb8();
    // let decoded = decode_helper(buf).unwrap_or((0,0));

    // println!("rust -> {:?} <- rust", decoded);

    // let vals = vec![decoded.0 as u8, decoded.1 as u8];

    Ok(_result)
}

#[no_mangle]
pub extern fn decode(b: &u8, l: u64) -> *const Vec<u8> {
    println!("{:?}", b);
    println!("{:?}", l);
    let result = _decode(b, l);
    match result {
        Ok(_val) => &vec![255,255,255],
        Err(_) => &vec![255,255,255],
    }
}

#[no_mangle]
pub extern fn hello() {
    println!("Hey there!: Curr dir is {}", std::env::current_dir().unwrap().display());
}
