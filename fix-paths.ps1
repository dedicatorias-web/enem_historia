# Fix GitHub Pages basePath for: https://dedicatorias-web.github.io/enem_historia/
# Substitui caminhos absolutos /_next/ e /logo.svg pelo basePath correto
# VERSAO 2 - usa git restore para restaurar os originais ANTES de reaplicar

$basePath = "/enem_historia"
$rootDir = $PSScriptRoot

Write-Host "=== Fix GitHub Pages Paths (v2 - UTF-8 Safe) ===" -ForegroundColor Cyan
Write-Host "BasePath: $basePath" -ForegroundColor Yellow
Write-Host "Diretorio: $rootDir" -ForegroundColor Yellow
Write-Host ""

# Passo 1: Restaurar arquivos originais do git para evitar double-replace
Write-Host "Restaurando arquivos originais do git..." -ForegroundColor Yellow

$htmlFiles = Get-ChildItem -Path $rootDir -Filter "*.html" -Recurse | Where-Object {
    $_.FullName -notlike "*\.agents*"
}

foreach ($f in $htmlFiles) {
    $rel = $f.FullName.Replace($rootDir + "\", "").Replace("\", "/")
    & git -C $rootDir checkout HEAD -- $rel 2>&1 | Out-Null
}

Write-Host "Arquivos restaurados. Aplicando substituicoes..." -ForegroundColor Green
Write-Host ""

$totalChanged = 0
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

foreach ($file in $htmlFiles) {
    # Ler como bytes e converter para string UTF-8 manualmente
    $bytes = [System.IO.File]::ReadAllBytes($file.FullName)
    $content = [System.Text.Encoding]::UTF8.GetString($bytes)
    $original = $content

    # 1. Corrigir src="/_next/ e href="/_next/ nos atributos HTML
    $content = $content -replace '(src|href)="/_next/', "`$1=`"$basePath/_next/"

    # 2. Corrigir href="/logo.svg" em atributos HTML
    $content = $content -replace 'href="/logo.svg"', "href=`"$basePath/logo.svg`""

    # 3. Corrigir "/_next/ dentro de strings JS inline (RSC payload)
    $content = $content -replace '"/_next/', "`"$basePath/_next/"

    # 4. Corrigir \"/_next/ dentro de JSON escapado nos scripts inline
    $content = $content -replace '\\\"/_next/', "\\`"$basePath/_next/"

    # 5. Corrigir "/logo.svg" dentro de strings JS
    $content = $content -replace '"\/logo\.svg"', "`"$basePath/logo.svg`""

    if ($content -ne $original) {
        # Salvar como UTF-8 sem BOM preservando todos os caracteres
        $outBytes = $utf8NoBom.GetBytes($content)
        [System.IO.File]::WriteAllBytes($file.FullName, $outBytes)
        $relativePath = $file.FullName.Replace($rootDir, "").TrimStart("\")
        Write-Host "  [OK] $relativePath" -ForegroundColor Green
        $totalChanged++
    } else {
        $relativePath = $file.FullName.Replace($rootDir, "").TrimStart("\")
        Write-Host "  [--] $relativePath (sem alteracoes)" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "=== Concluido! ===" -ForegroundColor Cyan
Write-Host "Arquivos modificados: $totalChanged / $($htmlFiles.Count)" -ForegroundColor Yellow
Write-Host ""
Write-Host "Proximo passo: commitar e fazer push para o GitHub!" -ForegroundColor Magenta
