
function Get-TestFromScript
{
    param (
        [parameter(Mandatory)]
        [string]$ScriptPath
    )

    $text = Get-Content -Path $ScriptPath -Raw
    $tokens = $null
    $errors = $null
    $describes = [Management.Automation.Language.Parser]::ParseInput($text, [ref]$tokens, [ref]$errors).
       FindAll([Func[Management.Automation.Language.Ast,bool]]{
            param ($ast)
            $ast.CommandElements -and
            $ast.CommandElements[0].Value -eq 'describe'
        }, $true) |
        ForEach-Object {
            # This is the name of the 'describe' block
            $describeName = ($_.CommandElements | Where-Object { $_.StaticType.name -eq 'string' })[1].SafeGetValue()

            $item = [PSCustomObject][ordered]@{
                Name = $describeName
                Tags = @()
            }

            # Get any tags defined
            $tagIndex = $_.CommandElements.IndexOf(($_.CommandElements | Where-Object ParameterName -eq 'Tag')) + 1
            if ($tagIndex -and $tagIndex -lt $_.CommandElements.Count) {
                $tagExtent = $_.CommandElements[$tagIndex].Extent

                $tagAST = [System.Management.Automation.Language.Parser]::ParseInput($tagExtent, [ref]$null, [ref]$null)

                # Try to get the tags as an array
                $tagElements = $tagAST.FindAll({$args[0] -is [System.Management.Automation.Language.ArrayLiteralAst]}, $true)
                if ($tagElements) {
                    $item.Tags = $tagElements.SafeGetValue()
                } else {
                    # Try to get the tag as a string
                    $tagElements = $tagAST.FindAll({$args[0] -is [System.Management.Automation.Language.StringConstantExpressionAst]}, $true)
                    if ($tagElements) {
                        $item.Tags = @($tagElements.SafeGetValue())
                    }
                }
            }
            $item
        }
    $describes
}
