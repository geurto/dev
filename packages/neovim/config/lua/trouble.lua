return {
    "folke/trouble.nvim",
    opts = {}, -- for default options, refer to the configuration section for custom setup.
    cmd = "Trouble",
    keys = {
        {
            "<leader>xX",
            "<cmd>Trouble diagnostics toggle<cr>",
            desc = "Diagnostics (Trouble)",
        },
        {
            "<leader>xx",
            "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
            desc = "Buffer Diagnostics (Trouble)",
        },
        {
            "<leader>cs",
            "<cmd>Trouble symbols toggle focus=false<cr>",
            desc = "Symbols (Trouble)",
        },
        {
            "<leader>cl",
            "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
            desc = "LSP Definitions / references / ... (Trouble)",
        },
        {
            "<leader>xL",
            "<cmd>Trouble loclist toggle<cr>",
            desc = "Location List (Trouble)",
        },
        {
            "<leader>xQ",
            "<cmd>Trouble qflist toggle<cr>",
            desc = "Quickfix List (Trouble)",
        },
        -- Added LSP references
        {
            "<leader>xr",
            "<cmd>Trouble lsp_references<cr>",
            desc = "LSP References (Trouble)",
        },
        -- Added LSP implementations
        {
            "<leader>xi",
            "<cmd>Trouble lsp_implementations<cr>",
            desc = "LSP Implementations (Trouble)",
        },
        -- Added LSP definitions
        {
            "<leader>xd",
            "<cmd>Trouble lsp_definitions<cr>",
            desc = "LSP Definitions (Trouble)",
        },
        -- Added LSP type definitions
        {
            "<leader>xt",
            "<cmd>Trouble lsp_type_definitions<cr>",
            desc = "LSP Type Definitions (Trouble)",
        },
    },
}
