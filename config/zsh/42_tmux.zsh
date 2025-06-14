## =============================
# * tmux configuration
## =============================

tmux-smart() {
    local dir_name=$(basename "$PWD")
    local session_name="$dir_name"
    local counter=1
    local create_layout=true
    local force_new=false
    
    # オプション解析
    while [[ $# -gt 0 ]]; do
        case $1 in
            -s|--simple)
                create_layout=false
                shift
                ;;
            -n|--new)
                force_new=true
                shift
                ;;
            --name)
                session_name="$2"
                shift 2
                ;;
            *)
                echo "使用方法: tmux-smart [-s|--simple] [-n|--new] [--name session_name]"
                return 1
                ;;
        esac
    done
    
    # 既存セッション確認（force_newでない場合）
    if [ "$force_new" = false ] && tmux has-session -t "$session_name" 2>/dev/null; then
        echo "📁 ディレクトリ: $(pwd)"
        echo "🔗 既存セッション「$session_name」にアタッチします"
        tmux attach -t "$session_name"
        return 0
    fi
    
    # 連番チェック（新しいセッション作成時）
    local original_name="$session_name"
    while tmux has-session -t "$session_name" 2>/dev/null; do
        session_name="${original_name}-${counter}"
        counter=$((counter + 1))
    done
    
    echo "📁 ディレクトリ: $(pwd)"
    echo "🆕 新しいセッション名: $session_name"
    
    if [ "$create_layout" = true ]; then
        # 3ペインレイアウト作成
        tmux new-session -d -s "$session_name"
        # ペイン1を上下に分割
        tmux splitw -d -t 1
        # ペイン1（上ペイン）の縦幅をリサイズ
        resize-pane -t 1 -D 10
        # ペイン1を左右に分割
        tmux splitw -h -d -t 1
        # ペイン2（左ペイン）の横幅をリサイズ
        resize-pane -t 1 -L 20
        # ペイン2（右ペイン）に移動
        tmux select-pane -t 2
        # neovimを起動
        tmux send-keys -t 2 'nvim' C-m
        # ペイン3を左右に分割
        tmux splitw -h -d -t 3
        # ペイン3（右ペイン）の横幅をリサイズ
        resize-pane -t 2 -R 20
        # ペイン1（上ペイン）に移動
        tmux select-pane -t 1
        # claudeコマンドを起動
        tmux send-keys -t 1 'claude' C-m
        
    else
        # シンプルなセッション
        tmux new-session -d -s "$session_name"
    fi
    
    tmux attach -t "$session_name"
}

alias tx='tmux-smart'
