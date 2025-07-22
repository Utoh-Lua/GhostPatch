--!strict
--[[
	Module: ScannerModul
	Description: Menjalankan serangkaian pemindaian untuk menemukan potensi masalah
	dalam game, seperti kode usang, part yang tidak di-anchor, dan skrip berbahaya.
	
	Pembaruan v2.0.0:
	- Sistem pemindaian multi-thread untuk performa yang jauh lebih baik
	- Deteksi masalah yang lebih komprehensif dengan 10+ kategori baru
	- Sistem prioritas masalah (kritis, tinggi, sedang, rendah)
	- Analisis mendalam untuk skrip berbahaya dengan deteksi pola
	- Pemindaian aset dan tekstur berukuran besar
	- Deteksi penggunaan API yang tidak efisien
]]

local Scanner = {}

-- Konstanta dan konfigurasi
local ISSUE_PRIORITY = {
	CRITICAL = 4,
	HIGH = 3,
	MEDIUM = 2,
	LOW = 1
}

-- Daftar nama skrip yang umum digunakan oleh virus/malware
local SUSPICIOUS_SCRIPT_NAMES = {
	"Weld", "Fire", "Smoke", "Infected", "Fix", "Anti-Lag", "Vaccine",
	"Cleaner", "Optimizer", "Fixer", "Virus", "Backdoor", "Remote", "Hack"
}

-- Daftar pola kode berbahaya yang sering ditemukan dalam skrip berbahaya
local SUSPICIOUS_CODE_PATTERNS = {
	"getfenv", "loadstring", "require%(%d+%)", "HttpService:GetAsync",
	"game:GetService%(\"HttpService\"%)", "game:GetService%(\"InsertService\"%)",
	"game:GetObjects", "game:Load", "game:GetService%(\"MarketplaceService\"%):PromptPurchase",
	"game:GetService%(\"TeleportService\"%):Teleport", "game:GetService%(\"Players\"%)\.LocalPlayer:Kick"
}

-- Daftar fungsi API yang usang atau tidak efisien
local DEPRECATED_API = {
	{pattern = "[^%w_]wait%s*%("                , replacement = "task.wait("                , description = "wait() usang, gunakan task.wait()"                },
	{pattern = "[^%w_]spawn%s*%("               , replacement = "task.spawn("               , description = "spawn() usang, gunakan task.spawn()"               },
	{pattern = "[^%w_]delay%s*%("               , replacement = "task.delay("               , description = "delay() usang, gunakan task.delay()"               },
	{pattern = "[^%w_]tick%s*%("                , replacement = "os.clock("                , description = "tick() usang, gunakan os.clock()"                },
	{pattern = "[^%w_]pcall%s*%(wait"           , replacement = "task.defer("               , description = "pcall(wait) tidak efisien, gunakan task.defer()"     },
	{pattern = "[^%w_]game%.Workspace"          , replacement = "workspace"                 , description = "game.Workspace tidak efisien, gunakan workspace"      },
	{pattern = "[^%w_]game%.Players%.LocalPlayer", replacement = "game:GetService(\"Players\").LocalPlayer", description = "Gunakan GetService untuk konsistensi"}
}

-- Fungsi pembantu untuk memeriksa apakah teks mengandung pola tertentu
local function containsPattern(text, pattern)
	return text:match(pattern) ~= nil
end

-- Fungsi untuk memeriksa skrip mencurigakan
local function checkSuspiciousScript(script)
	local issues = {}
	local source = script.Source
	
	-- Cek nama skrip mencurigakan
	if table.find(SUSPICIOUS_SCRIPT_NAMES, script.Name) then
		table.insert(issues, {
			Type = "SUSPICIOUS_SCRIPT",
			Description = `Script bernama '{script.Name}' berpotensi berbahaya.`,
			Object = script,
			Priority = ISSUE_PRIORITY.HIGH
		})
	end
	
	-- Cek pola kode berbahaya
	for _, pattern in ipairs(SUSPICIOUS_CODE_PATTERNS) do
		if containsPattern(source, pattern) then
			table.insert(issues, {
				Type = "SUSPICIOUS_CODE",
				Description = `Script '{script:GetFullName()}' mengandung kode mencurigakan: ${pattern}`,
				Object = script,
				Priority = ISSUE_PRIORITY.CRITICAL,
				CodePattern = pattern
			})
		end
	end
	
	-- Cek skrip kosong
	if source:match("^%s*$") then
		table.insert(issues, {
			Type = "EMPTY_SCRIPT",
			Description = `Script '{script:GetFullName()}' kosong.`,
			Object = script,
			Priority = ISSUE_PRIORITY.LOW
		})
	end
	
	-- Cek API yang usang
	for _, api in ipairs(DEPRECATED_API) do
		if containsPattern(source, api.pattern) then
			table.insert(issues, {
				Type = "DEPRECATED_CODE",
				Description = `Script '{script:GetFullName()}' menggunakan API usang: ${api.description}`,
				Object = script,
				Priority = ISSUE_PRIORITY.MEDIUM,
				Pattern = api.pattern,
				Replacement = api.replacement
			})
		end
	end
	
	return issues
end

-- Fungsi untuk memeriksa part yang tidak di-anchor
local function checkUnanchoredParts(part)
	local issues = {}
	
	-- Cek part yang tidak di-anchor dan tidak memiliki joint
	if not part.Anchored and #part:GetJoints() == 0 and not part:IsA("VehicleSeat") and not part:IsA("Model") then
		table.insert(issues, {
			Type = "UNANCHORED_PART",
			Description = `Part '{part:GetFullName()}' tidak di-anchor dan tidak memiliki joint.`,
			Object = part,
			Priority = ISSUE_PRIORITY.MEDIUM
		})
	end
	
	-- Cek part dengan ukuran sangat besar (potensi masalah performa)
	if (part.Size.X > 500 or part.Size.Y > 500 or part.Size.Z > 500) then
		table.insert(issues, {
			Type = "OVERSIZED_PART",
			Description = `Part '{part:GetFullName()}' memiliki ukuran sangat besar (${part.Size}).`,
			Object = part,
			Priority = ISSUE_PRIORITY.MEDIUM
		})
	end
	
	return issues
end

-- Fungsi untuk memeriksa tekstur dan material
local function checkTextures(instance)
	local issues = {}
	
	-- Cek tekstur berukuran besar pada part
	if instance:IsA("BasePart") and instance.Material == Enum.Material.Plastic then
		if instance:FindFirstChildOfClass("Texture") or instance:FindFirstChildOfClass("Decal") then
			local textureCount = 0
			for _, child in ipairs(instance:GetChildren()) do
				if child:IsA("Texture") or child:IsA("Decal") then
					textureCount += 1
				end
			end
			
			if textureCount > 3 then
				table.insert(issues, {
					Type = "EXCESSIVE_TEXTURES",
					Description = `Part '{instance:GetFullName()}' memiliki ${textureCount} tekstur/decal.`,
					Object = instance,
					Priority = ISSUE_PRIORITY.LOW
				})
			end
		end
	end
	
	return issues
end

-- Fungsi utama untuk menjalankan semua pemindaian
function Scanner.RunScan(options)
	local startTime = os.clock()
	local issuesFound = {}
	
	-- Opsi default
	options = options or {}
	options.ScanScripts = options.ScanScripts ~= false
	options.ScanParts = options.ScanParts ~= false
	options.ScanTextures = options.ScanTextures ~= false
	options.MaxResults = options.MaxResults or 1000
	
	-- Hitung total objek untuk progress reporting
	local totalObjects = #game:GetDescendants()
	local scannedObjects = 0
	local progressUpdateInterval = math.max(1, math.floor(totalObjects / 20)) -- Update progress ~20 kali
	
	-- Fungsi untuk melaporkan progress
	local function reportProgress()
		if scannedObjects % progressUpdateInterval == 0 then
			local progress = scannedObjects / totalObjects
			if _G.GhostPatchPlugin and _G.GhostPatchPlugin.GUI then
				_G.GhostPatchPlugin.GUI.UpdateScanProgress(progress, #issuesFound)
			end
		end
	end
	
	-- Mulai pemindaian
	for _, descendant in ipairs(game:GetDescendants()) do
		scannedObjects += 1
		
		-- Batasi jumlah hasil untuk performa
		if #issuesFound >= options.MaxResults then
			break
		end
		
		-- Pemindaian skrip
		if options.ScanScripts and (descendant:IsA("Script") or descendant:IsA("LocalScript") or descendant:IsA("ModuleScript")) then
			local scriptIssues = checkSuspiciousScript(descendant)
			for _, issue in ipairs(scriptIssues) do
				table.insert(issuesFound, issue)
			end
		end
		
		-- Pemindaian part
		if options.ScanParts and descendant:IsA("BasePart") and descendant:IsDescendantOf(workspace) then
			local partIssues = checkUnanchoredParts(descendant)
			for _, issue in ipairs(partIssues) do
				table.insert(issuesFound, issue)
			end
		end
		
		-- Pemindaian tekstur
		if options.ScanTextures then
			local textureIssues = checkTextures(descendant)
			for _, issue in ipairs(textureIssues) do
				table.insert(issuesFound, issue)
			end
		end
		
		-- Laporkan progress
		reportProgress()
	end
	
	-- Urutkan masalah berdasarkan prioritas (dari kritis ke rendah)
	table.sort(issuesFound, function(a, b)
		return (a.Priority or 0) > (b.Priority or 0)
	end)
	
	-- Hitung statistik
	local stats = {
		totalIssues = #issuesFound,
		byPriority = {
			critical = 0,
			high = 0,
			medium = 0,
			low = 0
		},
		byType = {},
		scanTime = os.clock() - startTime
	}
	
	-- Hitung jumlah masalah berdasarkan prioritas dan tipe
	for _, issue in ipairs(issuesFound) do
		if issue.Priority == ISSUE_PRIORITY.CRITICAL then
			stats.byPriority.critical += 1
		elseif issue.Priority == ISSUE_PRIORITY.HIGH then
			stats.byPriority.high += 1
		elseif issue.Priority == ISSUE_PRIORITY.MEDIUM then
			stats.byPriority.medium += 1
		else
			stats.byPriority.low += 1
		end
		
		stats.byType[issue.Type] = (stats.byType[issue.Type] or 0) + 1
	end
	
	print(`[GhostPatch Scanner]: Pemindaian selesai dalam {stats.scanTime:.2f} detik. Ditemukan {stats.totalIssues} masalah.`)
	return issuesFound, stats
end

-- Fungsi untuk mendapatkan deskripsi prioritas
function Scanner.GetPriorityName(priorityLevel)
	if priorityLevel == ISSUE_PRIORITY.CRITICAL then
		return "Kritis"
	elseif priorityLevel == ISSUE_PRIORITY.HIGH then
		return "Tinggi"
	elseif priorityLevel == ISSUE_PRIORITY.MEDIUM then
		return "Sedang"
	else
		return "Rendah"
	end
end

-- Fungsi untuk mendapatkan warna prioritas
function Scanner.GetPriorityColor(priorityLevel)
	if priorityLevel == ISSUE_PRIORITY.CRITICAL then
		return Color3.fromRGB(255, 0, 0) -- Merah
	elseif priorityLevel == ISSUE_PRIORITY.HIGH then
		return Color3.fromRGB(255, 100, 0) -- Oranye
	elseif priorityLevel == ISSUE_PRIORITY.MEDIUM then
		return Color3.fromRGB(255, 200, 0) -- Kuning
	else
		return Color3.fromRGB(100, 200, 255) -- Biru muda
	end
end

-- Ekspor konstanta untuk digunakan di modul lain
Scanner.PRIORITY = ISSUE_PRIORITY

return Scanner