@{
	# Module metadata
	ModuleVersion = '2.0.1'
	GUID = 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d'
	Author = 'Peter Kaagman'
	CompanyName = 'Atlas College'
	Copyright = '(c) 2025 Peter Kaagman. Licensed under MIT License.'
	Description = 'Module for testing conditions against nested hashtable structures and retrieving values from them.'

	# Module components
	RootModule = 'StructMatcher.psm1'
	PowerShellVersion = '5.1'

	# Functions to export
	FunctionsToExport = @('Invoke-StructMatcher')

	# Cmdlets to export
	CmdletsToExport = @()

	# Variables to export
	VariablesToExport = @()

	# Aliases to export
	AliasesToExport = @()

	# Private data
	PrivateData = @{
		PSData = @{
			Tags = @(
				'PowerShell', 
				'StructMatcher', 
				'RuleEngine', 
				'Conditions', 
				'Rules', 
				'JSON', 
				'Hashtable', 
				'PSCustomObject'
			)
			ReleaseNotes = @'
Exports Invoke-StructMatcher for evaluating conditions against nested structures.

2.0.1
- Refactored internal rule evaluation.
- Public API reduced to Invoke-StructMatcher.
- Added support for Hashtables, PSCustomObjects, and JSON text as input.

1.0.1
- Initial release
- Outer loop for rule evaluation not within the function, but rather in the calling context.
- Input data is expected to be a hashtable or PSCustomObject.
'@
			ProjectUri = 'https://github.com/peter-kaagman/Atlas-HelloID-Scripts'
		}
	}
}
