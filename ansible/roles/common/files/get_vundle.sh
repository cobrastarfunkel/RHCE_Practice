
for user in $(getent passwd | egrep -v "guest|nologin" | cut -d ":" -f1); do

    uid=$(id -u $user 2>/dev/null)

    if ((uid > 999)); then
        [[ -d /home/$user/.vim/bundle/Vundle.vim ]] || git clone https://github.com/VundleVim/Vundle.vim.git /home/$user/.vim/bundle/Vundle.vim;
        chown -R $user:$user /home/$user 2> /dev/null

    elif ((uid == 0)); then
        [[ -d /$user/.vim/bundle/Vundle.vim ]] || git clone https://github.com/VundleVim/Vundle.vim.git /$user/.vim/bundle/Vundle.vim;
    fi
done
