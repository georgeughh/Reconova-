## About Reconova

**Reconova** is a comprehensive Bash-based reconnaissance tool designed for security researchers and bug bounty hunters. It automates the process of discovering subdomains, checking their statuses, identifying technologies, and finding potential security issues like subdomain takeovers.

### 🚀 Key Features:
- **Subdomain Enumeration:** Uses tools like `subfinder`, `sublist3r`, `gobuster`, and `amass` for thorough subdomain discovery.  
- **HTTP Status Code Checking:** Uses `httpx` to filter subdomains by status codes (2xx, 3xx, 4xx, etc.).  
- **Subdomain Takeover Detection:** Leverages `subzy` to identify takeover vulnerabilities.  
- **Web Technology Enumeration:** Uses `whatweb` to detect technologies used on discovered subdomains.  
- **Endpoint and Parameter Discovery:** Utilizes `dirsearch` for endpoints and `arjun` for parameter fuzzing.  
- **Organized Outputs:** Saves results into clearly defined directories for easy access and analysis.  

### 🛠️ Dependencies:
Make sure the following tools are installed before running Reconova:
- `subfinder`  
- `sublist3r`  
- `gobuster`  
- `httpx`  
- `subzy`  
- `whatweb`  
- `dirsearch`  
- `arjun`  
- `amass`  
- `anew`  

### 💻 Usage:
```bash
chmod +x reconova.sh
./reconova.sh -d example.com
```
![Screenshot 2025-02-16 104625](https://github.com/user-attachments/assets/4945f14b-b720-4cde-aefb-68ea3156b401)

## CONTACT
- Twitter [@GerogeeSecc](https://x.com/GeorgeeSecc).
