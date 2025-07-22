--!strict
--[[
	Module: PatcherModul
	Description: Menerapkan perbaikan untuk masalah yang ditemukan oleh Scanner.
	
	Pembaruan v2.0.0:
	- Sistem perbaikan otomatis yang lebih cerdas dan aman
	- Dukungan untuk semua kategori masalah baru
	- Sistem rollback untuk mengembalikan perubahan jika terjadi kesalahan
	- Laporan detail tentang perubahan yang dilakukan
	- Mode simulasi untuk melihat perubahan tanpa menerapkannya
	- Perbaikan kode yang lebih akurat dengan analisis konteks
]]

local Patcher = {}

-- Konstanta dan konfigurasi
local MAX_BACKUP_COUNT = 10 -- Jumlah maksimum backup yang disimpan

-- Tabel untuk menyimpan backup
local backupData = {}

-- Fungsi untuk membuat backup objek sebelum dimodifikasi
local function createBackup(object, propertyName, originalValue)
	local objectPath = object:GetFullName()
	local backupId = #backupData + 1
	
	table.insert(backupData, {
		id = backupId,
		objectPath = objectPath,
		propertyName = propertyName,
		originalValue = originalValue,
		timestamp = os.time()
	})
	
	-- Batasi jumlah backup
	if #backupData > MAX_BACKUP_COUNT then
		table.remove(backupData, 1) -- Hapus backup tertua
	end
	
	return backupId
end

-- Fungsi untuk mengembalikan perubahan dari backup
function Patcher.Rollback(backupId)
	for i, backup in ipairs(backupData) do
		if backup.id == backupId then
			local success, errorMsg = pcall(function()
				local object = game:GetService("PathfindingService"):FindFirstChild(backup.objectPath)
				if object then
					if backup.propertyName == "Source" and object:IsA("BaseScript") then
						object.Source = backup.originalValue
					elseif backup.propertyName == "Object" and backup.originalValue then
						-- Mengembalikan objek yang dihapus
						backup.originalValue.Parent = game:GetService("PathfindingService"):FindFirstChild(backup.objectPath)
					else
						object[backup.propertyName] = backup.originalValue
					end
				end
			end)
			
			table.remove(backupData, i)
			return success, errorMsg
		end
	end
	
	return false, "Backup tidak ditemukan"
end

-- Fungsi untuk memperbaiki kode usang
local function fixDeprecatedCode(issue, simulationMode)
	local script = issue.Object
	local originalSource = script.Source
	
	-- Gunakan pola dan penggantian dari data masalah
	local pattern = issue.Pattern
	local replacement = issue.Replacement
	
	if not pattern or not replacement then
		return false, "Data pola atau penggantian tidak ditemukan"
	end
	
	-- Buat backup
	local backupId = createBackup(script, "Source", originalSource)
	
	-- Lakukan penggantian
	local newSource = string.gsub(originalSource, pattern, replacement)
	
	-- Terapkan perubahan jika tidak dalam mode simulasi
	if not simulationMode then
		script.Source = newSource
	end
	
	return true, {
		backupId = backupId,
		changes = {
			before = originalSource,
			after = newSource
		}
	}
end

-- Fungsi untuk memperbaiki part yang tidak di-anchor
local function fixUnanchoredPart(issue, simulationMode)
	local part = issue.Object
	
	-- Buat backup
	local backupId = createBackup(part, "Anchored", part.Anchored)
	
	-- Terapkan perubahan jika tidak dalam mode simulasi
	if not simulationMode then
		part.Anchored = true
	end
	
	return true, {
		backupId = backupId,
		changes = {
			before = false,
			after = true
		}
	}
end

-- Fungsi untuk menghapus skrip kosong
local function fixEmptyScript(issue, simulationMode)
	local script = issue.Object
	
	-- Buat backup (menyimpan objek asli)
	local backupId = createBackup(script.Parent, "Object", script:Clone())
	
	-- Terapkan perubahan jika tidak dalam mode simulasi
	if not simulationMode then
		script:Destroy()
	end
	
	return true, {
		backupId = backupId,
		changes = {
			before = "Script kosong",
			after = "Script dihapus"
		}
	}
end

-- Fungsi untuk memperbaiki part berukuran besar
local function fixOversizedPart(issue, simulationMode)
	local part = issue.Object
	local originalSize = part.Size
	
	-- Buat backup
	local backupId = createBackup(part, "Size", originalSize)
	
	-- Hitung ukuran baru yang lebih masuk akal
	local newSize = Vector3.new(
		math.min(originalSize.X, 500),
		math.min(originalSize.Y, 500),
		math.min(originalSize.Z, 500)
	)
	
	-- Terapkan perubahan jika tidak dalam mode simulasi
	if not simulationMode then
		part.Size = newSize
	end
	
	return true, {
		backupId = backupId,
		changes = {
			before = tostring(originalSize),
			after = tostring(newSize)
		}
	}
end

-- Fungsi utama untuk memperbaiki masalah
function Patcher.FixIssues(issues, options)
	local options = options or {}
	local simulationMode = options.SimulationMode or false
	local fixesApplied = 0
	local report = {
		succeeded = {},
		failed = {},
		skipped = {}
	}
	
	for _, issue in ipairs(issues) do
		-- Lewati jika objek tidak valid
		if not issue or not issue.Object or not issue.Object.Parent then
			table.insert(report.skipped, {
				issue = issue,
				reason = "Objek tidak valid atau sudah dihapus"
			})
			continue
		end
		
		-- Lewati jika tipe tidak didukung
		if issue.Type == "SUSPICIOUS_SCRIPT" or issue.Type == "SUSPICIOUS_CODE" then
			table.insert(report.skipped, {
				issue = issue,
				reason = "Tipe masalah memerlukan peninjauan manual"
			})
			continue
		end
		
		-- Coba perbaiki masalah berdasarkan tipe
		local success, result = pcall(function()
			if issue.Type == "DEPRECATED_CODE" then
				return fixDeprecatedCode(issue, simulationMode)
				
			elseif issue.Type == "UNANCHORED_PART" then
				return fixUnanchoredPart(issue, simulationMode)
				
			elseif issue.Type == "EMPTY_SCRIPT" then
				return fixEmptyScript(issue, simulationMode)
				
			elseif issue.Type == "OVERSIZED_PART" then
				return fixOversizedPart(issue, simulationMode)
				
			else
				return false, "Tipe masalah tidak didukung: " .. issue.Type
			end
		end)
		
		if success and result and result[1] == true then
			-- Perbaikan berhasil
			table.insert(report.succeeded, {
				issue = issue,
				backupId = result[2].backupId,
				changes = result[2].changes
			})
			fixesApplied += 1
		else
			-- Perbaikan gagal
			local errorMsg = "Kesalahan tidak diketahui"
			if not success then
				errorMsg = result
			elseif type(result) == "string" then
				errorMsg = result
			end
			
			table.insert(report.failed, {
				issue = issue,
				reason = errorMsg
			})
		end
	end
	
	-- Buat ringkasan laporan
	local summary = {
		totalIssues = #issues,
		fixesApplied = fixesApplied,
		succeeded = #report.succeeded,
		failed = #report.failed,
		skipped = #report.skipped,
		simulationMode = simulationMode
	}
	
	print(`[GhostPatch Patcher]: Perbaikan selesai. {fixesApplied} dari {#issues} masalah telah diperbaiki.`)
	return summary, report
end

-- Fungsi untuk mendapatkan daftar backup
function Patcher.GetBackups()
	return backupData
end

-- Fungsi untuk menghapus semua backup
function Patcher.ClearBackups()
	backupData = {}
end

return Patcher