#!/bin/bash

echo ">>> Installing Node.js and PM2..."
export DEBIAN_FRONTEND=noninteractive
# Using Node.js 22 (LTS)
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt-get install -y nodejs

# Update npm to latest to avoid "new version available" notices
npm install -g npm@latest
npm install -g pm2

echo ">>> Registering PM2 as a systemd startup service for vagrant user..."
# Generate the startup script and execute it so PM2 is launched on every boot
# 1. 'sudo -u vagrant': Runs the command as the 'vagrant' user.
#    bash: Starts a new shell session. 
#    -c: Command, "execute the following immediately"
# 2. 'pm2 startup systemd': Asks PM2 to generate the specific systemd configuration 
#    string required to launch on boot for this specific OS.
# 3. '-u vagrant --hp /home/vagrant': Explicitly tells PM2 which user and home 
#    directory should own the process.
# 4. '| tail -1': The 'pm2 startup' command outputs a block of text; the actual 
#    command you need to run is always on the very last line. This strips the fluff.
# 5. '| bash': Takes that last line (the generated command) and executes it 
#    immediately with administrative privileges.
sudo -u vagrant bash -c "pm2 startup systemd -u vagrant --hp /home/vagrant" | tail -1 | bash

# Version where root owns the PM2 process list
# pm2 startup systemd -u root --hp /root | tail -1 | bash

echo ">>> PM2 installed and registered with systemd."
