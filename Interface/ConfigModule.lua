--!strict
--[[
	File: ConfigModule.lua
	Description: Menyimpan semua pengaturan gaya (warna, font, ukuran) untuk GUI.
	
	Pembaruan v2.0.0:
	- Tema modern dengan gradien dan efek bayangan
	- Dukungan untuk tema terang dan gelap
	- Pengaturan animasi dan transisi
	- Konfigurasi untuk semua komponen UI baru
	- Palet warna yang lebih kaya dan konsisten
]]

local Config = {}

-- Tema Utama (Bisa diubah oleh pengguna)
Config.CurrentTheme = "Dark" -- "Dark" atau "Light"

-- Palet Warna Tema Gelap (Modern & Profesional)
Config.Themes = {
	Dark = {
		-- Warna Latar
		Background = Color3.fromRGB(30, 32, 36),       -- Latar belakang utama
		BackgroundSecondary = Color3.fromRGB(38, 40, 45), -- Latar belakang sekunder
		BackgroundTertiary = Color3.fromRGB(45, 48, 56),  -- Latar belakang tersier
		
		-- Warna Aksen & Interaksi
		Primary = Color3.fromRGB(88, 101, 242),        -- Warna utama (ungu-biru)
		PrimaryLight = Color3.fromRGB(120, 130, 255),  -- Warna utama lebih terang
		PrimaryDark = Color3.fromRGB(70, 80, 200),     -- Warna utama lebih gelap
		Secondary = Color3.fromRGB(59, 165, 93),       -- Warna sekunder (hijau)
		
		-- Warna Status
		Success = Color3.fromRGB(67, 181, 129),        -- Sukses (hijau)
		Warning = Color3.fromRGB(250, 168, 26),        -- Peringatan (oranye)
		Danger = Color3.fromRGB(240, 71, 71),          -- Bahaya (merah)
		Info = Color3.fromRGB(88, 166, 255),           -- Informasi (biru)
		
		-- Warna Teks
		Text = Color3.fromRGB(230, 232, 235),          -- Teks utama
		TextSecondary = Color3.fromRGB(185, 187, 190), -- Teks sekunder
		TextMuted = Color3.fromRGB(140, 142, 145),     -- Teks redup
		TextLink = Color3.fromRGB(88, 166, 255),       -- Teks link
		
		-- Warna Batas & Pemisah
		Border = Color3.fromRGB(50, 53, 59),           -- Batas standar
		BorderLight = Color3.fromRGB(60, 63, 70),      -- Batas ringan
		Divider = Color3.fromRGB(48, 51, 56),          -- Pemisah
		
		-- Warna Prioritas Masalah
		PriorityCritical = Color3.fromRGB(240, 71, 71),  -- Prioritas kritis
		PriorityHigh = Color3.fromRGB(250, 168, 26),     -- Prioritas tinggi
		PriorityMedium = Color3.fromRGB(250, 212, 0),    -- Prioritas sedang
		PriorityLow = Color3.fromRGB(88, 166, 255),      -- Prioritas rendah
	},
	
	Light = {
		-- Warna Latar
		Background = Color3.fromRGB(255, 255, 255),      -- Latar belakang utama
		BackgroundSecondary = Color3.fromRGB(245, 246, 250), -- Latar belakang sekunder
		BackgroundTertiary = Color3.fromRGB(235, 237, 240),  -- Latar belakang tersier
		
		-- Warna Aksen & Interaksi
		Primary = Color3.fromRGB(88, 101, 242),        -- Warna utama (ungu-biru)
		PrimaryLight = Color3.fromRGB(120, 130, 255),  -- Warna utama lebih terang
		PrimaryDark = Color3.fromRGB(70, 80, 200),     -- Warna utama lebih gelap
		Secondary = Color3.fromRGB(59, 165, 93),       -- Warna sekunder (hijau)
		
		-- Warna Status
		Success = Color3.fromRGB(67, 181, 129),        -- Sukses (hijau)
		Warning = Color3.fromRGB(250, 168, 26),        -- Peringatan (oranye)
		Danger = Color3.fromRGB(240, 71, 71),          -- Bahaya (merah)
		Info = Color3.fromRGB(88, 166, 255),           -- Informasi (biru)
		
		-- Warna Teks
		Text = Color3.fromRGB(30, 32, 36),             -- Teks utama
		TextSecondary = Color3.fromRGB(70, 72, 76),    -- Teks sekunder
		TextMuted = Color3.fromRGB(110, 112, 115),     -- Teks redup
		TextLink = Color3.fromRGB(70, 80, 200),        -- Teks link
		
		-- Warna Batas & Pemisah
		Border = Color3.fromRGB(220, 223, 230),        -- Batas standar
		BorderLight = Color3.fromRGB(230, 233, 240),   -- Batas ringan
		Divider = Color3.fromRGB(225, 228, 235),       -- Pemisah
		
		-- Warna Prioritas Masalah
		PriorityCritical = Color3.fromRGB(220, 50, 50),  -- Prioritas kritis
		PriorityHigh = Color3.fromRGB(230, 150, 20),     -- Prioritas tinggi
		PriorityMedium = Color3.fromRGB(230, 190, 0),    -- Prioritas sedang
		PriorityLow = Color3.fromRGB(70, 140, 220),      -- Prioritas rendah
	}
}

-- Pengaturan Font
Config.Fonts = {
	Family = Enum.Font.Gotham,
	Title = {
		Size = 24,
		Weight = Enum.FontWeight.Bold
	},
	Heading = {
		Size = 18,
		Weight = Enum.FontWeight.SemiBold
	},
	Subheading = {
		Size = 16,
		Weight = Enum.FontWeight.Medium
	},
	Body = {
		Size = 14,
		Weight = Enum.FontWeight.Regular
	},
	Small = {
		Size = 12,
		Weight = Enum.FontWeight.Regular
	},
	Tiny = {
		Size = 10,
		Weight = Enum.FontWeight.Regular
	}
}

-- Pengaturan Layout
Config.Layout = {
	Padding = {
		Small = 6,
		Medium = 12,
		Large = 18,
		ExtraLarge = 24
	},
	CornerRadius = {
		Small = 4,
		Medium = 8,
		Large = 12,
		Round = 9999 -- Untuk bentuk bulat
	},
	Spacing = {
		Tiny = 4,
		Small = 8,
		Medium = 12,
		Large = 16,
		ExtraLarge = 24
	},
	BorderSize = {
		Thin = 1,
		Medium = 2,
		Thick = 3
	},
	Shadow = {
		None = 0,
		Small = 2,
		Medium = 4,
		Large = 8
	},
	MaxWidth = 800, -- Lebar maksimum jendela
	MinWidth = 400, -- Lebar minimum jendela
	MaxHeight = 600, -- Tinggi maksimum jendela
	MinHeight = 300, -- Tinggi minimum jendela
}

-- Pengaturan Animasi
Config.Animation = {
	Duration = {
		Fast = 0.1,
		Medium = 0.2,
		Slow = 0.3,
		ExtraSlow = 0.5
	},
	Easing = {
		Linear = Enum.EasingStyle.Linear,
		Quad = Enum.EasingStyle.Quad,
		Cubic = Enum.EasingStyle.Cubic,
		Quart = Enum.EasingStyle.Quart,
		Quint = Enum.EasingStyle.Quint,
		Back = Enum.EasingStyle.Back,
		Elastic = Enum.EasingStyle.Elastic,
		Bounce = Enum.EasingStyle.Bounce
	},
	Direction = {
		In = Enum.EasingDirection.In,
		Out = Enum.EasingDirection.Out,
		InOut = Enum.EasingDirection.InOut
	}
}

-- Pengaturan Komponen
Config.Components = {
	Button = {
		Height = 36,
		Padding = 12,
		CornerRadius = 6
	},
	Input = {
		Height = 36,
		Padding = 12,
		CornerRadius = 6
	},
	Checkbox = {
		Size = 20,
		CornerRadius = 4
	},
	Radio = {
		Size = 20
	},
	Toggle = {
		Width = 44,
		Height = 24,
		KnobSize = 18
	},
	Dropdown = {
		Height = 36,
		MaxHeight = 200,
		ItemHeight = 32
	},
	Tab = {
		Height = 40,
		IndicatorHeight = 3
	},
	Card = {
		Padding = 16,
		CornerRadius = 8
	},
	Modal = {
		Width = 400,
		Padding = 24,
		CornerRadius = 12
	},
	Toast = {
		Height = 48,
		Padding = 16,
		CornerRadius = 8,
		Duration = 3 -- Durasi tampilan dalam detik
	},
	ProgressBar = {
		Height = 8,
		CornerRadius = 4
	},
	Slider = {
		Height = 8,
		KnobSize = 16
	},
	Tooltip = {
		Padding = 8,
		CornerRadius = 4,
		ArrowSize = 6
	}
}

-- Fungsi untuk mendapatkan warna berdasarkan tema saat ini
function Config.GetColor(colorName)
	local theme = Config.Themes[Config.CurrentTheme]
	if theme and theme[colorName] then
		return theme[colorName]
	else
		-- Fallback ke warna default jika tidak ditemukan
		return Color3.fromRGB(255, 255, 255)
	end
end

-- Fungsi untuk mengubah tema
function Config.SetTheme(themeName)
	if Config.Themes[themeName] then
		Config.CurrentTheme = themeName
		return true
	else
		return false
	end
end

-- Fungsi untuk mendapatkan tema saat ini
function Config.GetCurrentTheme()
	return Config.CurrentTheme
end

-- Fungsi untuk mendapatkan semua tema yang tersedia
function Config.GetAvailableThemes()
	local themes = {}
	for themeName, _ in pairs(Config.Themes) do
		table.insert(themes, themeName)
	end
	return themes
end

return Config