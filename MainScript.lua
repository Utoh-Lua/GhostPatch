--!strict
--[[
	File: Main.lua
	Description: Titik masuk utama plugin. Membuat tombol toolbar dan mendelegasikan pembuatan GUI ke modul GUI.
]]

-- Memuat modul GUI
local GUI = require(script.Parent.GUI)

-- Membuat Toolbar baru bernama "My Plugins" (akan menggunakan yang sudah ada jika tersedia)
local toolbar = plugin:CreateToolbar("My Plugins")

-- Membuat tombol untuk membuka plugin GhostPatch
local button = toolbar:CreateButton(
	"GhostPatch", -- ID unik untuk tombol
	"Buka GhostPatch - Alat Optimisasi", -- Tooltip saat mouse hover
	"rbxassetid://4454849384" -- Contoh ikon (ikon 'magic wand')
)

-- Menghubungkan fungsi klik tombol ke fungsi Toggle di modul GUI
button.Click:Connect(function()
	GUI.Toggle()
end)

print("GhostPatch Plugin Loaded.")