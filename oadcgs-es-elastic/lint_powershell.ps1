$changes = git diff --name-only

Foreach ($change in $changes)
{
  Invoke-ScriptAnalyzer $change -Settings PSScriptAnalyzerSettings.psd1 -Fix
}
