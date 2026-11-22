![Status](https://img.shields.io/badge/NOTICE-In_Development-purple)

<div align="center">
<img src="Resources/Images/invert_slys.png" alt="Texto alternativo" width="400" />
</div>

## 
File encrypted fragmentator for privacy built in Rust

## Why? 
We're increasingly exposed to organizations and institutions accessing our files without clear or informed consent. This tool is a response to that intrusion — a way to fragment and encrypt your data so it can't be easily read or reconstructed without your permission.

By splitting and encrypting the content, it adds an extra layer of security: sensitive information can remain on your device without being immediately accessible. Only with the correct password and the Slys-generated seed can the original file be restored, giving full control back to the user.

Additionally, the application includes a self-erasing mechanism after a defined period of inactivity. This doesn't just remove the program's pointer—it securely wipes its own data by overwriting it with zeros, ensuring nothing recoverable is left behind.

In the event that something happens to the user, the fragmented data remains on the system but becomes completely inaccessible. However, this does not prevent the user from reinstalling the tool later and reintroducing the seed to reconstruct the original files when needed.

## Capabilities 
### 1. **File Fragmentation & Encryption**
- Splits a selected file into multiple fragments.  
- Each fragment is encrypted individually using a user-defined password.  
- Fragments are stored in a way that prevents reconstruction without proper credentials.

### 2. **Seed Generation for Reconstruction**
- After fragmentation, the system generates a unique seed required to reconstruct the original file.  
- The seed itself is encrypted and must be stored securely by the user.  
- Only with both the password and the seed can the file be fully restored via Slys.

### 3. **Secure Self-Erasure on Inactivity** *(Planned Feature)*
- The application can auto-delete itself after a defined period of inactivity.  
- This includes secure data wiping through zero-overwriting, not just removing executables.  
- Ensures that if something happens to the user, sensitive data remains physically present but completely inaccessible.

### 4. **Recoverability via Reinstallation**
- Even after self-erasure, users can reinstall the tool and reintroduce the encrypted seed to reconstruct their files.  
- This ensures long-term control and access without compromising on security.

   
## Instalation
 <img src="https://img.shields.io/badge/-UNDER_CONSTRUCTION-red?style=for-the-badge&logo=tools&logoColor=black" alt="Under Construction Badge">
 
## Usage
 <img src="https://img.shields.io/badge/-UNDER_CONSTRUCTION-red?style=for-the-badge&logo=tools&logoColor=black" alt="Under Construction Badge">



