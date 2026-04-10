-- 行番号
vim.opt.number = true          -- 絶対行番号を表示

-- カーソル
vim.opt.cursorline = true      -- カーソル行をハイライト
vim.opt.cursorcolumn = false   -- カーソル列のハイライトはオフ（見づらいため）

-- インデント
vim.opt.tabstop = 2            -- タブ幅を2スペースに
vim.opt.shiftwidth = 2         -- 自動インデント幅を2スペースに
vim.opt.expandtab = true       -- タブをスペースに展開

-- 検索
vim.opt.ignorecase = true      -- 検索時に大文字小文字を区別しない
vim.opt.smartcase = true       -- 大文字を含む場合は区別する
vim.opt.hlsearch = true        -- 検索結果をハイライト
vim.opt.incsearch = true       -- インクリメンタルサーチを有効化

-- 表示
vim.opt.wrap = false           -- 長い行を折り返さない
vim.opt.scrolloff = 8          -- カーソル上下に常に8行の余白を確保
vim.opt.signcolumn = "yes"     -- 左端のサイン列を常に表示（ガタつき防止）
vim.opt.termguicolors = true   -- 24bit カラーを有効化

-- 操作
vim.opt.mouse = "a"            -- 全モードでマウスを有効化
vim.opt.clipboard = "unnamedplus"  -- システムクリップボードと連携

-- ファイル
vim.opt.swapfile = false       -- スワップファイルを作成しない
vim.opt.backup = false         -- バックアップファイルを作成しない
vim.opt.undofile = true        -- アンドゥ履歴をファイルに保存（再起動後も有効）

-- <leader> キーをスペースに設定
vim.g.mapleader = " "

-- キーマップ: Esc で検索ハイライトを消す
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")
