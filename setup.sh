#!/bin/bash

export HOSTNAME=hogwarts
export USER=bbraunj
export SERVER_MODE=1

# This script to be run as root after performing an arch-chroot from the installation media.
# See the appropriate point in the installation guide: https://wiki.archlinux.org/title/Installation_guide#Chroot
ln -sf /usr/share/zoneinfo/US/Central /etc/localtime
hwclock --systohc
sed -i 's/#\(en_US.UTF-8 UTF-8\)/\1/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf
echo $HOSTNAME > /etc/hostname

# Update pacman sources
pacman -Sy --noconfirm

echo "* Setting up NetworkManager"
pacman -S --noconfirm networkmanager
systemctl enable NetworkManager.service
systemctl start NetworkManager.service

echo "* Setting the root password..."
passwd

echo "* Setting up grub"
pacman -S --noconfirm grub efibootmgr
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

echo "* Setting up the user '$USER'"
useradd -m -U $USER
passwd $USER

echo "* Adding $USER to the sudo group"
pacman -S --noconfirm sudo 
groupadd sudo
usermod -G sudo $USER
echo "%sudo   ALL=(ALL:ALL) ALL" >> /etc/sudoers

echo "* Setting up SSH"
pacman -S --noconfirm openssh
systemctl enable sshd.service
systemctl start sshd.service
su $USER << EOF
ssh-keygen -t ed25519 -a 100 -N '' -f /home/$USER/.ssh/id_rsa
echo -e "\n${USER}'s public ssh key:"
cat /home/$USER/.ssh/id_rsa.pub
echo
EOF

echo "* Installing several other packages I like :)"
pacman -S --noconfirm pkginfo neovim python3

# Miscellaneous preferences
echo "* Adding essential preferences..."
cat >> /etc/profile.d/aliases.sh << EOF
alias vi=nvim
EOF

if [[ $SERVER_MODE == 1 ]]; then
  # Disable sleep on lid close. Essential for a laptop server.
  sed -i 's/#\(HandleLidSwitch\)/\1/' /etc/systemd/logind.conf
fi

su $USER << EOF
echo "set -o vi" >> /home/$USER/.bashrc

mkdir -p /home/$USER/.config/nvim
echo "set rnu" >> /home/$USER/.config/nvim/init.vim

EOF
