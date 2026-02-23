@{
    ExcludeRules = @(
        # TUI library — Write-Host is intentional for direct terminal output
        'PSAvoidUsingWriteHost'

        # Chicle-* naming is a deliberate project convention, not Verb-Noun
        'PSUseApprovedVerbs'

        # Chicle-Steps — plural is intentional
        'PSUseSingularNouns'

        # UTF-8 without BOM is standard
        'PSUseBOMForUnicodeEncodedFile'
    )

    Severity = @('Error', 'Warning')
}
