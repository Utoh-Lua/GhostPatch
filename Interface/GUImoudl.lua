--!strict
--[[
	Module: GUImoudl
	Description: Modul antarmuka pengguna untuk GhostPatch. Menangani pembuatan dan interaksi GUI.
	
	Pembaruan v2.0.0:
	- Antarmuka pengguna yang sepenuhnya didesain ulang dengan tema modern
	- Sistem tab untuk navigasi yang lebih baik
	- Visualisasi data dengan grafik dan statistik
	- Animasi dan transisi yang halus
	- Mode gelap dan terang
	- Komponen UI yang dapat digunakan kembali
	- Responsif dan dapat disesuaikan ukurannya
]]

local GUIModule = {}

-- Referensi ke plugin dan layanan
local plugin = _G.GhostPatchPlugin and _G.GhostPatchPlugin.Plugin
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- Referensi ke modul lain
local Config = _G.GhostPatchPlugin and _G.GhostPatchPlugin.Config or require(script.Parent.ConfigModule)
local Scanner = _G.GhostPatchPlugin and _G.GhostPatchPlugin.Scanner or require(script.Parent.Parent.Core.ScannerModul)
local Patcher = _G.GhostPatchPlugin and _G.GhostPatchPlugin.Patcher or require(script.Parent.Parent.Core.PatcherModul)

-- Variabel untuk menyimpan referensi ke GUI
local gui = nil
local widgetInfo = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Float, -- Mulai dalam keadaan mengambang
	true, -- Widget akan diaktifkan saat dibuat
	false, -- Jangan aktifkan otomatis saat dimuat
	650, -- Lebar default
	500, -- Tinggi default
	400, -- Lebar minimum
	300 -- Tinggi minimum
)

-- Variabel untuk menyimpan status dan data
local currentTab = "Dashboard"
local isScanning = false
local scanResults = nil
local scanStats = nil
local fixResults = nil
local scanProgress = 0

-- Komponen UI yang dapat digunakan kembali
local UIComponents = {}

-- Fungsi untuk membuat tombol
function UIComponents.CreateButton(parent, text, position, size, onClick, style)
	style = style or "primary" -- primary, secondary, danger, success, outline
	
	local button = Instance.new("TextButton")
	button.Name = "Button_" .. text
	button.Size = size or UDim2.new(0, 120, 0, Config.Components.Button.Height)
	button.Position = position or UDim2.new(0, 0, 0, 0)
	button.BackgroundColor3 = style == "primary" and Config.GetColor("Primary") or
							style == "secondary" and Config.GetColor("Secondary") or
							style == "danger" and Config.GetColor("Danger") or
							style == "success" and Config.GetColor("Success") or
							style == "outline" and Config.GetColor("Background")
	button.BorderSizePixel = style == "outline" and 1 or 0
	button.BorderColor3 = style == "outline" and Config.GetColor("Primary") or Config.GetColor("Border")
	button.Text = text
	button.TextColor3 = style == "outline" and Config.GetColor("Primary") or Config.GetColor("Text")
	button.Font = Config.Fonts.Family
	button.TextSize = Config.Fonts.Body.Size
	button.AutoButtonColor = true
	button.Parent = parent
	
	-- Membuat sudut bulat
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, Config.Components.Button.CornerRadius)
	corner.Parent = button
	
	-- Menambahkan padding
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, Config.Components.Button.Padding)
	padding.PaddingRight = UDim.new(0, Config.Components.Button.Padding)
	padding.Parent = button
	
	-- Menambahkan efek hover
	button.MouseEnter:Connect(function()
		local targetColor
		if style == "primary" then
			targetColor = Config.GetColor("PrimaryLight")
		elseif style == "secondary" then
			targetColor = Config.GetColor("Secondary"):Lerp(Color3.new(1, 1, 1), 0.1)
		elseif style == "danger" then
			targetColor = Config.GetColor("Danger"):Lerp(Color3.new(1, 1, 1), 0.1)
		elseif style == "success" then
			targetColor = Config.GetColor("Success"):Lerp(Color3.new(1, 1, 1), 0.1)
		elseif style == "outline" then
			targetColor = Config.GetColor("Primary"):Lerp(Config.GetColor("Background"), 0.9)
		end
		
		TweenService:Create(button, TweenInfo.new(0.1), {BackgroundColor3 = targetColor}):Play()
	end)
	
	button.MouseLeave:Connect(function()
		local originalColor = style == "primary" and Config.GetColor("Primary") or
								style == "secondary" and Config.GetColor("Secondary") or
								style == "danger" and Config.GetColor("Danger") or
								style == "success" and Config.GetColor("Success") or
								style == "outline" and Config.GetColor("Background")
		
		TweenService:Create(button, TweenInfo.new(0.1), {BackgroundColor3 = originalColor}):Play()
	end)
	
	-- Menambahkan efek klik
	button.MouseButton1Click:Connect(function()
		-- Efek visual saat diklik
		local clickColor = style == "outline" and Config.GetColor("Primary"):Lerp(Config.GetColor("Background"), 0.7) or
							button.BackgroundColor3:Lerp(Color3.new(0, 0, 0), 0.1)
		
		TweenService:Create(button, TweenInfo.new(0.05), {BackgroundColor3 = clickColor}):Play()
		
		-- Panggil fungsi callback
		if onClick then
			onClick()
		end
		
		-- Kembalikan ke warna hover
		task.delay(0.05, function()
			local hoverColor = style == "primary" and Config.GetColor("PrimaryLight") or
								style == "secondary" and Config.GetColor("Secondary"):Lerp(Color3.new(1, 1, 1), 0.1) or
								style == "danger" and Config.GetColor("Danger"):Lerp(Color3.new(1, 1, 1), 0.1) or
								style == "success" and Config.GetColor("Success"):Lerp(Color3.new(1, 1, 1), 0.1) or
								style == "outline" and Config.GetColor("Primary"):Lerp(Config.GetColor("Background"), 0.9)
			
			TweenService:Create(button, TweenInfo.new(0.1), {BackgroundColor3 = hoverColor}):Play()
		end)
	end)
	
	return button
end

-- Fungsi untuk membuat label
function UIComponents.CreateLabel(parent, text, position, size, textOptions)
	textOptions = textOptions or {}
	
	local label = Instance.new("TextLabel")
	label.Name = "Label_" .. text:sub(1, math.min(20, #text))
	label.Size = size or UDim2.new(1, 0, 0, 20)
	label.Position = position or UDim2.new(0, 0, 0, 0)
	label.BackgroundTransparency = textOptions.BackgroundTransparency or 1
	label.BackgroundColor3 = textOptions.BackgroundColor3 or Config.GetColor("Background")
	label.BorderSizePixel = 0
	label.Text = text
	label.TextColor3 = textOptions.TextColor3 or Config.GetColor("Text")
	label.Font = textOptions.Font or Config.Fonts.Family
	label.TextSize = textOptions.TextSize or Config.Fonts.Body.Size
	label.TextXAlignment = textOptions.TextXAlignment or Enum.TextXAlignment.Left
	label.TextYAlignment = textOptions.TextYAlignment or Enum.TextYAlignment.Center
	label.TextWrapped = textOptions.TextWrapped or false
	label.RichText = textOptions.RichText or false
	label.Parent = parent
	
	return label
end

-- Fungsi untuk membuat input teks
function UIComponents.CreateTextInput(parent, placeholderText, position, size, onChange)
	local frame = Instance.new("Frame")
	frame.Name = "InputFrame_" .. placeholderText
	frame.Size = size or UDim2.new(1, 0, 0, Config.Components.Input.Height)
	frame.Position = position or UDim2.new(0, 0, 0, 0)
	frame.BackgroundColor3 = Config.GetColor("BackgroundTertiary")
	frame.BorderSizePixel = 0
	frame.Parent = parent
	
	-- Membuat sudut bulat
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, Config.Components.Input.CornerRadius)
	corner.Parent = frame
	
	-- Membuat input teks
	local input = Instance.new("TextBox")
	input.Name = "Input"
	input.Size = UDim2.new(1, 0, 1, 0)
	input.Position = UDim2.new(0, 0, 0, 0)
	input.BackgroundTransparency = 1
	input.Text = ""
	input.PlaceholderText = placeholderText
	input.PlaceholderColor3 = Config.GetColor("TextMuted")
	input.TextColor3 = Config.GetColor("Text")
	input.Font = Config.Fonts.Family
	input.TextSize = Config.Fonts.Body.Size
	input.TextXAlignment = Enum.TextXAlignment.Left
	input.ClearTextOnFocus = false
	input.Parent = frame
	
	-- Menambahkan padding
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, Config.Components.Input.Padding)
	padding.PaddingRight = UDim.new(0, Config.Components.Input.Padding)
	padding.Parent = input
	
	-- Menambahkan efek fokus
	input.Focused:Connect(function()
		TweenService:Create(frame, TweenInfo.new(0.1), {BackgroundColor3 = Config.GetColor("BackgroundTertiary"):Lerp(Config.GetColor("Primary"), 0.1)}):Play()
	end)
	
	input.FocusLost:Connect(function(enterPressed)
		TweenService:Create(frame, TweenInfo.new(0.1), {BackgroundColor3 = Config.GetColor("BackgroundTertiary")}):Play()
		
		if onChange then
			onChange(input.Text, enterPressed)
		end
	end)
	
	return input
end

-- Fungsi untuk membuat checkbox
function UIComponents.CreateCheckbox(parent, text, position, checked, onChange)
	local frame = Instance.new("Frame")
	frame.Name = "Checkbox_" .. text
	frame.Size = UDim2.new(1, 0, 0, Config.Components.Checkbox.Size + 6)
	frame.Position = position or UDim2.new(0, 0, 0, 0)
	frame.BackgroundTransparency = 1
	frame.Parent = parent
	
	-- Membuat kotak checkbox
	local box = Instance.new("Frame")
	box.Name = "Box"
	box.Size = UDim2.new(0, Config.Components.Checkbox.Size, 0, Config.Components.Checkbox.Size)
	box.Position = UDim2.new(0, 0, 0.5, -Config.Components.Checkbox.Size/2)
	box.BackgroundColor3 = Config.GetColor("BackgroundTertiary")
	box.BorderSizePixel = 0
	box.Parent = frame
	
	-- Membuat sudut bulat untuk kotak
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, Config.Components.Checkbox.CornerRadius)
	corner.Parent = box
	
	-- Membuat ikon centang
	local checkmark = Instance.new("ImageLabel")
	checkmark.Name = "Checkmark"
	checkmark.Size = UDim2.new(0.7, 0, 0.7, 0)
	checkmark.Position = UDim2.new(0.15, 0, 0.15, 0)
	checkmark.BackgroundTransparency = 1
	checkmark.Image = "rbxassetid://6031094667" -- ID aset untuk ikon centang
	checkmark.ImageColor3 = Config.GetColor("Text")
	checkmark.Visible = checked or false
	checkmark.Parent = box
	
	-- Membuat label teks
	local label = UIComponents.CreateLabel(frame, text, UDim2.new(0, Config.Components.Checkbox.Size + 8, 0, 0), UDim2.new(1, -(Config.Components.Checkbox.Size + 8), 1, 0))
	
	-- Membuat tombol transparan untuk interaksi
	local button = Instance.new("TextButton")
	button.Name = "Button"
	button.Size = UDim2.new(1, 0, 1, 0)
	button.BackgroundTransparency = 1
	button.Text = ""
	button.Parent = frame
	
	-- Menambahkan interaksi
	button.MouseButton1Click:Connect(function()
		checkmark.Visible = not checkmark.Visible
		
		if checkmark.Visible then
			-- Animasi saat dicentang
			box.BackgroundColor3 = Config.GetColor("Primary")
			checkmark.ImageTransparency = 1
			TweenService:Create(checkmark, TweenInfo.new(0.2), {ImageTransparency = 0}):Play()
		else
			-- Animasi saat tidak dicentang
			TweenService:Create(box, TweenInfo.new(0.2), {BackgroundColor3 = Config.GetColor("BackgroundTertiary")}):Play()
		end
		
		if onChange then
			onChange(checkmark.Visible)
		end
	end)
	
	-- Menambahkan efek hover
	button.MouseEnter:Connect(function()
		if not checkmark.Visible then
			TweenService:Create(box, TweenInfo.new(0.1), {BackgroundColor3 = Config.GetColor("BackgroundTertiary"):Lerp(Config.GetColor("Primary"), 0.2)}):Play()
		end
	end)
	
	button.MouseLeave:Connect(function()
		if not checkmark.Visible then
			TweenService:Create(box, TweenInfo.new(0.1), {BackgroundColor3 = Config.GetColor("BackgroundTertiary")}):Play()
		end
	end)
	
	return {
		Frame = frame,
		Checkmark = checkmark,
		IsChecked = function() return checkmark.Visible end,
		SetChecked = function(value)
			checkmark.Visible = value
			if value then
				box.BackgroundColor3 = Config.GetColor("Primary")
			else
				box.BackgroundColor3 = Config.GetColor("BackgroundTertiary")
			end
		end
	}
end

-- Fungsi untuk membuat tab
function UIComponents.CreateTabButton(parent, text, isActive, onClick)
	local button = Instance.new("TextButton")
	button.Name = "Tab_" .. text
	button.Size = UDim2.new(0, 100, 1, 0)
	button.BackgroundTransparency = 1
	button.Text = text
	button.TextColor3 = isActive and Config.GetColor("Primary") or Config.GetColor("TextSecondary")
	button.Font = Config.Fonts.Family
	button.TextSize = Config.Fonts.Body.Size
	button.Parent = parent
	
	-- Membuat indikator tab aktif
	local indicator = Instance.new("Frame")
	indicator.Name = "Indicator"
	indicator.Size = UDim2.new(0.8, 0, 0, Config.Components.Tab.IndicatorHeight)
	indicator.Position = UDim2.new(0.1, 0, 1, -Config.Components.Tab.IndicatorHeight)
	indicator.BackgroundColor3 = Config.GetColor("Primary")
	indicator.BorderSizePixel = 0
	indicator.Visible = isActive
	indicator.Parent = button
	
	-- Membuat sudut bulat untuk indikator
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, Config.Components.Tab.IndicatorHeight / 2)
	corner.Parent = indicator
	
	-- Menambahkan interaksi
	button.MouseButton1Click:Connect(function()
		if onClick then
			onClick(text)
		end
	end)
	
	-- Menambahkan efek hover
	button.MouseEnter:Connect(function()
		if not isActive then
			TweenService:Create(button, TweenInfo.new(0.1), {TextColor3 = Config.GetColor("Text")}):Play()
		end
	end)
	
	button.MouseLeave:Connect(function()
		if not isActive then
			TweenService:Create(button, TweenInfo.new(0.1), {TextColor3 = Config.GetColor("TextSecondary")}):Play()
		end
	end)
	
	return {
		Button = button,
		Indicator = indicator,
		SetActive = function(active)
			isActive = active
			button.TextColor3 = active and Config.GetColor("Primary") or Config.GetColor("TextSecondary")
			indicator.Visible = active
			
			if active then
				-- Animasi saat tab menjadi aktif
				indicator.Size = UDim2.new(0, 0, 0, Config.Components.Tab.IndicatorHeight)
				indicator.Position = UDim2.new(0.5, 0, 1, -Config.Components.Tab.IndicatorHeight)
				TweenService:Create(indicator, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Size = UDim2.new(0.8, 0, 0, Config.Components.Tab.IndicatorHeight),
					Position = UDim2.new(0.1, 0, 1, -Config.Components.Tab.IndicatorHeight)
				}):Play()
			end
		end
	}
end

-- Fungsi untuk membuat kartu
function UIComponents.CreateCard(parent, title, position, size)
	local card = Instance.new("Frame")
	card.Name = "Card_" .. title
	card.Size = size or UDim2.new(1, 0, 0, 200)
	card.Position = position or UDim2.new(0, 0, 0, 0)
	card.BackgroundColor3 = Config.GetColor("BackgroundSecondary")
	card.BorderSizePixel = 0
	card.Parent = parent
	
	-- Membuat sudut bulat
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, Config.Components.Card.CornerRadius)
	corner.Parent = card
	
	-- Menambahkan bayangan (opsional)
	local shadow = Instance.new("ImageLabel")
	shadow.Name = "Shadow"
	shadow.Size = UDim2.new(1, 20, 1, 20)
	shadow.Position = UDim2.new(0, -10, 0, -10)
	shadow.BackgroundTransparency = 1
	shadow.Image = "rbxassetid://6014261993" -- ID aset untuk bayangan
	shadow.ImageColor3 = Color3.new(0, 0, 0)
	shadow.ImageTransparency = 0.8
	shadow.ScaleType = Enum.ScaleType.Slice
	shadow.SliceCenter = Rect.new(49, 49, 450, 450)
	shadow.ZIndex = card.ZIndex - 1
	shadow.Parent = card
	
	-- Menambahkan judul
	local titleLabel = nil
	if title and title ~= "" then
		titleLabel = UIComponents.CreateLabel(card, title, UDim2.new(0, Config.Components.Card.Padding, 0, Config.Components.Card.Padding), UDim2.new(1, -Config.Components.Card.Padding*2, 0, 24), {
			TextSize = Config.Fonts.Subheading.Size,
			Font = Config.Fonts.Family,
			TextColor3 = Config.GetColor("Text")
		})
	end
	
	-- Menambahkan container untuk konten
	local content = Instance.new("Frame")
	content.Name = "Content"
	content.Size = UDim2.new(1, -Config.Components.Card.Padding*2, 1, -(Config.Components.Card.Padding*2 + (titleLabel and 30 or 0)))
	content.Position = UDim2.new(0, Config.Components.Card.Padding, 0, Config.Components.Card.Padding + (titleLabel and 30 or 0))
	content.BackgroundTransparency = 1
	content.Parent = card
	
	return {
		Card = card,
		Content = content,
		Title = titleLabel
	}
end

-- Fungsi untuk membuat progress bar
function UIComponents.CreateProgressBar(parent, position, size, progress, color)
	local frame = Instance.new("Frame")
	frame.Name = "ProgressBar"
	frame.Size = size or UDim2.new(1, 0, 0, Config.Components.ProgressBar.Height)
	frame.Position = position or UDim2.new(0, 0, 0, 0)
	frame.BackgroundColor3 = Config.GetColor("BackgroundTertiary")
	frame.BorderSizePixel = 0
	frame.Parent = parent
	
	-- Membuat sudut bulat
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, Config.Components.ProgressBar.CornerRadius)
	corner.Parent = frame
	
	-- Membuat bar kemajuan
	local bar = Instance.new("Frame")
	bar.Name = "Bar"
	bar.Size = UDim2.new(progress or 0, 0, 1, 0)
	bar.BackgroundColor3 = color or Config.GetColor("Primary")
	bar.BorderSizePixel = 0
	bar.Parent = frame
	
	-- Membuat sudut bulat untuk bar
	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(0, Config.Components.ProgressBar.CornerRadius)
	barCorner.Parent = bar
	
	return {
		Frame = frame,
		Bar = bar,
		SetProgress = function(value)
			value = math.clamp(value, 0, 1)
			TweenService:Create(bar, TweenInfo.new(0.2), {Size = UDim2.new(value, 0, 1, 0)}):Play()
		end,
		SetColor = function(newColor)
			bar.BackgroundColor3 = newColor
		end
	}
end

-- Fungsi untuk membuat daftar masalah
function UIComponents.CreateIssueList(parent, issues)
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "IssueList"
	scrollFrame.Size = UDim2.new(1, 0, 1, 0)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = 6
	scrollFrame.ScrollBarImageColor3 = Config.GetColor("Border")
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0) -- Akan diperbarui nanti
	scrollFrame.Parent = parent
	
	-- Menambahkan layout untuk daftar
	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, Config.Layout.Spacing.Small)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = scrollFrame
	
	-- Menambahkan padding
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, Config.Layout.Padding.Small)
	padding.PaddingBottom = UDim.new(0, Config.Layout.Padding.Small)
	padding.PaddingLeft = UDim.new(0, Config.Layout.Padding.Small)
	padding.PaddingRight = UDim.new(0, Config.Layout.Padding.Small)
	padding.Parent = scrollFrame
	
	-- Fungsi untuk membuat item masalah
	local function createIssueItem(issue, index)
		local item = Instance.new("Frame")
		item.Name = "Issue_" .. index
		item.Size = UDim2.new(1, 0, 0, 60)
		item.BackgroundColor3 = Config.GetColor("BackgroundTertiary")
		item.BorderSizePixel = 0
		item.LayoutOrder = index
		item.Parent = scrollFrame
		
		-- Membuat sudut bulat
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 6)
		corner.Parent = item
		
		-- Menambahkan indikator prioritas
		local priorityColor
		local priorityName
		
		if issue.Priority == Scanner.PRIORITY.CRITICAL then
			priorityColor = Config.GetColor("PriorityCritical")
			priorityName = "Kritis"
		elseif issue.Priority == Scanner.PRIORITY.HIGH then
			priorityColor = Config.GetColor("PriorityHigh")
			priorityName = "Tinggi"
		elseif issue.Priority == Scanner.PRIORITY.MEDIUM then
			priorityColor = Config.GetColor("PriorityMedium")
			priorityName = "Sedang"
		else
			priorityColor = Config.GetColor("PriorityLow")
			priorityName = "Rendah"
		end
		
		local priorityIndicator = Instance.new("Frame")
		priorityIndicator.Name = "PriorityIndicator"
		priorityIndicator.Size = UDim2.new(0, 4, 1, -16)
		priorityIndicator.Position = UDim2.new(0, 8, 0, 8)
		priorityIndicator.BackgroundColor3 = priorityColor
		priorityIndicator.BorderSizePixel = 0
		priorityIndicator.Parent = item
		
		-- Membuat sudut bulat untuk indikator
		local indicatorCorner = Instance.new("UICorner")
		indicatorCorner.CornerRadius = UDim.new(0, 2)
		indicatorCorner.Parent = priorityIndicator
		
		-- Menambahkan label tipe masalah
		local typeLabel = UIComponents.CreateLabel(item, issue.Type, UDim2.new(0, 20, 0, 8), UDim2.new(0.5, -20, 0, 20), {
			TextColor3 = Config.GetColor("TextSecondary"),
			TextSize = Config.Fonts.Small.Size
		})
		
		-- Menambahkan label prioritas
		local priorityLabel = UIComponents.CreateLabel(item, priorityName, UDim2.new(0.5, 0, 0, 8), UDim2.new(0.5, -8, 0, 20), {
			TextColor3 = priorityColor,
			TextSize = Config.Fonts.Small.Size,
			TextXAlignment = Enum.TextXAlignment.Right
		})
		
		-- Menambahkan deskripsi masalah
		local descriptionLabel = UIComponents.CreateLabel(item, issue.Description, UDim2.new(0, 20, 0, 28), UDim2.new(1, -28, 0, 32), {
			TextColor3 = Config.GetColor("Text"),
			TextWrapped = true,
			TextYAlignment = Enum.TextYAlignment.Top
		})
		
		return item
	end
	
	-- Membuat item untuk setiap masalah
	if issues and #issues > 0 then
		for i, issue in ipairs(issues) do
			createIssueItem(issue, i)
		end
		
		-- Perbarui ukuran kanvas
		scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + Config.Layout.Padding.Small * 2)
	else
		-- Tampilkan pesan jika tidak ada masalah
		local noIssuesLabel = UIComponents.CreateLabel(scrollFrame, "Tidak ada masalah yang ditemukan.", UDim2.new(0, 0, 0, 40), UDim2.new(1, 0, 0, 40), {
			TextColor3 = Config.GetColor("TextSecondary"),
			TextXAlignment = Enum.TextXAlignment.Center
		})
	end
	
	return scrollFrame
end

-- Fungsi untuk membuat statistik pemindaian
function UIComponents.CreateScanStats(parent, stats)
	local frame = Instance.new("Frame")
	frame.Name = "ScanStats"
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundTransparency = 1
	frame.Parent = parent
	
	-- Menambahkan layout grid
	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize = UDim2.new(0.5, -10, 0, 80)
	gridLayout.CellPadding = UDim2.new(0, 20, 0, 20)
	gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	gridLayout.Parent = frame
	
	-- Menambahkan padding
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, Config.Layout.Padding.Medium)
	padding.PaddingBottom = UDim.new(0, Config.Layout.Padding.Medium)
	padding.PaddingLeft = UDim.new(0, Config.Layout.Padding.Medium)
	padding.PaddingRight = UDim.new(0, Config.Layout.Padding.Medium)
	padding.Parent = frame
	
	-- Fungsi untuk membuat kartu statistik
	local function createStatCard(title, value, color, icon, layoutOrder)
		local card = Instance.new("Frame")
		card.Name = "Stat_" .. title
		card.BackgroundColor3 = Config.GetColor("BackgroundTertiary")
		card.BorderSizePixel = 0
		card.LayoutOrder = layoutOrder
		card.Parent = frame
		
		-- Membuat sudut bulat
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = card
		
		-- Menambahkan ikon (opsional)
		if icon then
			local iconLabel = Instance.new("ImageLabel")
			iconLabel.Name = "Icon"
			iconLabel.Size = UDim2.new(0, 32, 0, 32)
			iconLabel.Position = UDim2.new(0, 16, 0, 16)
			iconLabel.BackgroundTransparency = 1
			iconLabel.Image = icon
			iconLabel.ImageColor3 = color
			iconLabel.Parent = card
		end
		
		-- Menambahkan judul
		local titleLabel = UIComponents.CreateLabel(card, title, UDim2.new(0, icon and 58 or 16, 0, 16), UDim2.new(1, -(icon and 58 or 16) - 16, 0, 20), {
			TextColor3 = Config.GetColor("TextSecondary"),
			TextSize = Config.Fonts.Small.Size
		})
		
		-- Menambahkan nilai
		local valueLabel = UIComponents.CreateLabel(card, tostring(value), UDim2.new(0, icon and 58 or 16, 0, 36), UDim2.new(1, -(icon and 58 or 16) - 16, 0, 32), {
			TextColor3 = Config.GetColor("Text"),
			TextSize = Config.Fonts.Heading.Size,
			Font = Enum.Font.GothamBold
		})
		
		return card
	end
	
	-- Membuat kartu statistik
	if stats then
		createStatCard("Total Masalah", stats.totalIssues, Config.GetColor("Info"), "rbxassetid://6031071053", 1)
		createStatCard("Masalah Kritis", stats.byPriority.critical, Config.GetColor("PriorityCritical"), "rbxassetid://6031071057", 2)
		createStatCard("Waktu Pemindaian", string.format("%.2f detik", stats.scanTime), Config.GetColor("Secondary"), "rbxassetid://6026568247", 3)
		
		-- Menghitung persentase masalah yang dapat diperbaiki
		local fixableIssues = stats.totalIssues - (stats.byType["SUSPICIOUS_SCRIPT"] or 0) - (stats.byType["SUSPICIOUS_CODE"] or 0)
		local fixablePercent = stats.totalIssues > 0 and math.floor((fixableIssues / stats.totalIssues) * 100) or 100
		createStatCard("Dapat Diperbaiki", fixablePercent .. "%", Config.GetColor("Success"), "rbxassetid://6031289449", 4)
	else
		-- Tampilkan placeholder jika tidak ada statistik
		createStatCard("Total Masalah", "--", Config.GetColor("Info"), "rbxassetid://6031071053", 1)
		createStatCard("Masalah Kritis", "--", Config.GetColor("PriorityCritical"), "rbxassetid://6031071057", 2)
		createStatCard("Waktu Pemindaian", "--", Config.GetColor("Secondary"), "rbxassetid://6026568247", 3)
		createStatCard("Dapat Diperbaiki", "--", Config.GetColor("Success"), "rbxassetid://6031289449", 4)
	end
	
	return frame
end

-- Fungsi untuk membuat UI utama
local function createMainUI()
	-- Membuat widget
	gui = plugin:CreateDockWidgetPluginGui("GhostPatchUI", widgetInfo)
	gui.Title = "GhostPatch v" .. (_G.GhostPatchPlugin and _G.GhostPatchPlugin.Version or "2.0.0")
	gui.Name = "GhostPatchUI"
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	
	-- Membuat frame utama
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(1, 0, 1, 0)
	mainFrame.BackgroundColor3 = Config.GetColor("Background")
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = gui
	
	-- Membuat header
	local headerFrame = Instance.new("Frame")
	headerFrame.Name = "Header"
	headerFrame.Size = UDim2.new(1, 0, 0, 60)
	headerFrame.BackgroundColor3 = Config.GetColor("BackgroundSecondary")
	headerFrame.BorderSizePixel = 0
	headerFrame.Parent = mainFrame
	
	-- Menambahkan logo
	local logo = Instance.new("ImageLabel")
	logo.Name = "Logo"
	logo.Size = UDim2.new(0, 40, 0, 40)
	logo.Position = UDim2.new(0, 16, 0, 10)
	logo.BackgroundTransparency = 1
	logo.Image = "rbxassetid://7734051052" -- Ganti dengan ID aset logo yang valid
	logo.Parent = headerFrame
	
	-- Menambahkan judul
	local title = UIComponents.CreateLabel(headerFrame, "GhostPatch", UDim2.new(0, 66, 0, 10), UDim2.new(0.5, -66, 0, 24), {
		TextSize = Config.Fonts.Title.Size,
		Font = Enum.Font.GothamBold,
		TextColor3 = Config.GetColor("Text")
	})
	
	-- Menambahkan subtitle
	local subtitle = UIComponents.CreateLabel(headerFrame, "Optimasi & Keamanan Game", UDim2.new(0, 66, 0, 34), UDim2.new(0.5, -66, 0, 16), {
		TextSize = Config.Fonts.Small.Size,
		TextColor3 = Config.GetColor("TextSecondary")
	})
	
	-- Menambahkan tombol tema
	local themeButton = UIComponents.CreateButton(headerFrame, Config.CurrentTheme == "Dark" and "☀️ Tema Terang" or "🌙 Tema Gelap", UDim2.new(1, -140, 0, 15), UDim2.new(0, 120, 0, 30), function()
		local newTheme = Config.CurrentTheme == "Dark" and "Light" or "Dark"
		Config.SetTheme(newTheme)
		
		-- Tutup dan buka kembali GUI untuk menerapkan tema baru
		GUIModule.Toggle()
		task.delay(0.1, function()
			GUIModule.Toggle()
		end)
	end, "outline")
	
	-- Membuat tab bar
	local tabBar = Instance.new("Frame")
	tabBar.Name = "TabBar"
	tabBar.Size = UDim2.new(1, 0, 0, Config.Components.Tab.Height)
	tabBar.Position = UDim2.new(0, 0, 0, 60)
	tabBar.BackgroundColor3 = Config.GetColor("BackgroundSecondary")
	tabBar.BorderSizePixel = 0
	tabBar.Parent = mainFrame
	
	-- Menambahkan pemisah di bawah tab bar
	local tabDivider = Instance.new("Frame")
	tabDivider.Name = "TabDivider"
	tabDivider.Size = UDim2.new(1, 0, 0, 1)
	tabDivider.Position = UDim2.new(0, 0, 1, 0)
	tabDivider.BackgroundColor3 = Config.GetColor("Divider")
	tabDivider.BorderSizePixel = 0
	tabDivider.Parent = tabBar
	
	-- Membuat tab layout
	local tabLayout = Instance.new("UIListLayout")
	tabLayout.FillDirection = Enum.FillDirection.Horizontal
	tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
	tabLayout.Parent = tabBar
	
	-- Membuat container konten
	local contentContainer = Instance.new("Frame")
	contentContainer.Name = "ContentContainer"
	contentContainer.Size = UDim2.new(1, 0, 1, -(60 + Config.Components.Tab.Height))
	contentContainer.Position = UDim2.new(0, 0, 0, 60 + Config.Components.Tab.Height)
	contentContainer.BackgroundTransparency = 1
	contentContainer.Parent = mainFrame
	
	-- Membuat tab dan konten
	local tabs = {}
	local tabButtons = {}
	local tabContents = {}
	
	-- Fungsi untuk beralih tab
	local function switchTab(tabName)
		for name, button in pairs(tabButtons) do
			button.SetActive(name == tabName)
		end
		
		for name, content in pairs(tabContents) do
			content.Visible = (name == tabName)
		end
		
		currentTab = tabName
	end
	
	-- Membuat tab Dashboard
	tabButtons["Dashboard"] = UIComponents.CreateTabButton(tabBar, "Dashboard", currentTab == "Dashboard", switchTab)
	tabButtons["Dashboard"].Button.LayoutOrder = 1
	
	tabContents["Dashboard"] = Instance.new("ScrollingFrame")
	tabContents["Dashboard"].Name = "DashboardContent"
	tabContents["Dashboard"].Size = UDim2.new(1, 0, 1, 0)
	tabContents["Dashboard"].BackgroundTransparency = 1
	tabContents["Dashboard"].BorderSizePixel = 0
	tabContents["Dashboard"].ScrollBarThickness = 6
	tabContents["Dashboard"].ScrollBarImageColor3 = Config.GetColor("Border")
	tabContents["Dashboard"].Visible = currentTab == "Dashboard"
	tabContents["Dashboard"].Parent = contentContainer
	
	-- Menambahkan layout untuk Dashboard
	local dashboardLayout = Instance.new("UIListLayout")
	dashboardLayout.Padding = UDim.new(0, Config.Layout.Spacing.Medium)
	dashboardLayout.SortOrder = Enum.SortOrder.LayoutOrder
	dashboardLayout.Parent = tabContents["Dashboard"]
	
	-- Menambahkan padding untuk Dashboard
	local dashboardPadding = Instance.new("UIPadding")
	dashboardPadding.PaddingTop = UDim.new(0, Config.Layout.Padding.Medium)
	dashboardPadding.PaddingBottom = UDim.new(0, Config.Layout.Padding.Medium)
	dashboardPadding.PaddingLeft = UDim.new(0, Config.Layout.Padding.Medium)
	dashboardPadding.PaddingRight = UDim.new(0, Config.Layout.Padding.Medium)
	dashboardPadding.Parent = tabContents["Dashboard"]
	
	-- Membuat kartu ringkasan
	local summaryCard = UIComponents.CreateCard(tabContents["Dashboard"], "Ringkasan Game", nil, UDim2.new(1, 0, 0, 120))
	summaryCard.Card.LayoutOrder = 1
	
	-- Menambahkan statistik game
	local gameStats = {
		{name = "Jumlah Part", value = #workspace:GetDescendants()},
		{name = "Jumlah Script", value = 0},
		{name = "Ukuran Game", value = "--"},
		{name = "Waktu Muat", value = "--"}
	}
	
	-- Hitung jumlah skrip
	local scriptCount = 0
	for _, descendant in ipairs(game:GetDescendants()) do
		if descendant:IsA("BaseScript") then
			scriptCount += 1
		end
	end
	gameStats[2].value = scriptCount
	
	-- Membuat layout grid untuk statistik
	local statsGrid = Instance.new("Frame")
	statsGrid.Name = "StatsGrid"
	statsGrid.Size = UDim2.new(1, 0, 1, 0)
	statsGrid.BackgroundTransparency = 1
	statsGrid.Parent = summaryCard.Content
	
	local statsGridLayout = Instance.new("UIGridLayout")
	statsGridLayout.CellSize = UDim2.new(0.25, -10, 1, 0)
	statsGridLayout.CellPadding = UDim2.new(0, 10, 0, 0)
	statsGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	statsGridLayout.Parent = statsGrid
	
	-- Menambahkan statistik ke grid
	for i, stat in ipairs(gameStats) do
		local statFrame = Instance.new("Frame")
		statFrame.Name = "Stat_" .. stat.name
		statFrame.BackgroundTransparency = 1
		statFrame.LayoutOrder = i
		statFrame.Parent = statsGrid
		
		local statName = UIComponents.CreateLabel(statFrame, stat.name, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 20), {
			TextColor3 = Config.GetColor("TextSecondary"),
			TextSize = Config.Fonts.Small.Size,
			TextXAlignment = Enum.TextXAlignment.Center
		})
		
		local statValue = UIComponents.CreateLabel(statFrame, tostring(stat.value), UDim2.new(0, 0, 0, 25), UDim2.new(1, 0, 0, 30), {
			TextColor3 = Config.GetColor("Text"),
			TextSize = Config.Fonts.Heading.Size,
			Font = Enum.Font.GothamBold,
			TextXAlignment = Enum.TextXAlignment.Center
		})
	end
	
	-- Membuat kartu pemindaian
	local scanCard = UIComponents.CreateCard(tabContents["Dashboard"], "Pemindaian Cepat", nil, UDim2.new(1, 0, 0, 180))
	scanCard.Card.LayoutOrder = 2
	
	-- Menambahkan opsi pemindaian
	local scanOptions = {
		{name = "Periksa Skrip", default = true},
		{name = "Periksa Part", default = true},
		{name = "Periksa Tekstur", default = true}
	}
	
	local optionsFrame = Instance.new("Frame")
	optionsFrame.Name = "OptionsFrame"
	optionsFrame.Size = UDim2.new(1, 0, 0, 80)
	optionsFrame.BackgroundTransparency = 1
	optionsFrame.Parent = scanCard.Content
	
	local optionsLayout = Instance.new("UIListLayout")
	optionsLayout.Padding = UDim.new(0, Config.Layout.Spacing.Small)
	optionsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	optionsLayout.Parent = optionsFrame
	
	local checkboxes = {}
	for i, option in ipairs(scanOptions) do
		checkboxes[option.name] = UIComponents.CreateCheckbox(optionsFrame, option.name, nil, option.default, function(checked)
			-- Callback saat checkbox diubah
		end)
		checkboxes[option.name].Frame.LayoutOrder = i
	end
	
	-- Menambahkan progress bar
	local scanProgressFrame = Instance.new("Frame")
	scanProgressFrame.Name = "ScanProgressFrame"
	scanProgressFrame.Size = UDim2.new(1, 0, 0, 40)
	scanProgressFrame.Position = UDim2.new(0, 0, 0, 90)
	scanProgressFrame.BackgroundTransparency = 1
	scanProgressFrame.Visible = false
	scanProgressFrame.Parent = scanCard.Content
	
	local progressLabel = UIComponents.CreateLabel(scanProgressFrame, "Memindai...", UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 20), {
		TextColor3 = Config.GetColor("TextSecondary")
	})
	
	local progressBar = UIComponents.CreateProgressBar(scanProgressFrame, UDim2.new(0, 0, 0, 25), UDim2.new(1, 0, 0, 8), 0)
	
	-- Menambahkan tombol pemindaian
	local scanButtonFrame = Instance.new("Frame")
	scanButtonFrame.Name = "ScanButtonFrame"
	scanButtonFrame.Size = UDim2.new(1, 0, 0, 40)
	scanButtonFrame.Position = UDim2.new(0, 0, 0, 90)
	scanButtonFrame.BackgroundTransparency = 1
	scanButtonFrame.Parent = scanCard.Content
	
	local scanButton = UIComponents.CreateButton(scanButtonFrame, "Mulai Pemindaian", UDim2.new(0, 0, 0, 0), UDim2.new(0.48, 0, 1, 0), function()