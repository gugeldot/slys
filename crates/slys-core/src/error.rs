use std::io;

pub type Result<T> = std::result::Result<T, Error>;

/// Everything that can go wrong. Messages are written for end users: the UI shows them as-is.
#[derive(Debug, thiserror::Error)]
pub enum Error {
    #[error("I/O error: {0}")]
    Io(#[from] io::Error),

    #[error("The input file was not found or is not a regular file: {0}")]
    InputNotFound(String),

    #[error("Cannot split a file of {size} bytes into {parts} fragments")]
    TooManyParts { size: u64, parts: usize },

    #[error("The number of fragments must be between {min} and {max}")]
    InvalidParts { min: usize, max: usize },

    #[error("The password cannot be empty")]
    EmptyPassword,

    #[error("The seed looks mistyped or incomplete (checksum mismatch). Copy it again and make sure nothing is missing")]
    SeedChecksum,

    #[error("This is not a valid SLYS seed: {0}")]
    SeedMalformed(&'static str),

    #[error("Seed format version {0} is not supported by this version of SLYS")]
    UnsupportedVersion(u8),

    #[error("Wrong password, or the seed has been modified")]
    WrongPasswordOrTampered,

    #[error("Wrong password or corrupted data (legacy 1.x seed)")]
    LegacyDecrypt,

    #[error("Fragment not found: {0}")]
    FragmentMissing(String),

    #[error("Fragment {0} has been modified, is truncated, or does not belong to this seed")]
    FragmentCorrupted(String),

    #[error("The recomposed file does not match the original (integrity check failed). Nothing was written")]
    IntegrityMismatch,

    #[error("The output file already exists: {0}")]
    OutputExists(String),

    #[error("The seed contains an unsafe file name")]
    UnsafeName,

    #[error("The key derivation parameters in the seed are out of the accepted range")]
    KdfParams,

    #[error("Cryptographic failure")]
    Crypto,

    #[error("Storage error: {0}")]
    Storage(String),
}

impl From<argon2::Error> for Error {
    fn from(_: argon2::Error) -> Self {
        Error::KdfParams
    }
}
