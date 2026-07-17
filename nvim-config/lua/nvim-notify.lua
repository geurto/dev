local notify = require("notify")

notify.setup({
	background_colour = "#000000",

	vim.keymap.set("n", "<leader>pd", function()
		notify.dismiss()
	end, { desc = "Dismiss Notify message" }),
})
