$operatorCases = @(
    @{ Name = "Equals";         Operator = "Equals";         Path = @("person", "department"); Check = "Finance" }
    @{ Name = "NotEquals";      Operator = "NotEquals";      Path = @("person", "department"); Check = "IT" }
    @{ Name = "Contains";       Operator = "Contains";       Path = @("person", "roles");      Check = "Approver" }
    @{ Name = "NotContains";    Operator = "NotContains";    Path = @("person", "roles");      Check = "Guest" }
    @{ Name = "In";             Operator = "In";             Path = @("person", "department"); Check = '["HR","Finance"]' }
    @{ Name = "NotIn";          Operator = "NotIn";          Path = @("person", "department"); Check = '["HR","IT"]' }
    @{ Name = "Like";           Operator = "Like";           Path = @("person", "name");       Check = "John*" }
    @{ Name = "NotLike";        Operator = "NotLike";        Path = @("person", "name");       Check = "Jane*" }
    @{ Name = "Match";          Operator = "Match";          Path = @("person", "name");       Check = "^John" }
    @{ Name = "NotMatch";       Operator = "NotMatch";       Path = @("person", "name");       Check = "^Jane" }
    @{ Name = "GreaterThan";    Operator = "GreaterThan";    Path = @("person", "age");        Check = 30 }
    @{ Name = "LessThan";       Operator = "LessThan";       Path = @("person", "age");        Check = 40 }
    @{ Name = "GreaterOrEqual"; Operator = "GreaterOrEqual"; Path = @("person", "age");        Check = 35 }
    @{ Name = "LessOrEqual";    Operator = "LessOrEqual";    Path = @("person", "age");        Check = 35 }
)

$operatorNegativeCases = @(
    @{ Name = "Equals";          Operator = "Equals";          Path = @("person", "department"); Check = "IT" }
    @{ Name = "NotEquals";       Operator = "NotEquals";       Path = @("person", "department"); Check = "Finance" }
    @{ Name = "Contains";        Operator = "Contains";        Path = @("person", "roles");       Check = "Guest" }
    @{ Name = "NotContains";     Operator = "NotContains";     Path = @("person", "roles");       Check = "Approver" }
    @{ Name = "In";              Operator = "In";              Path = @("person", "department"); Check = '["HR","IT"]' }
    @{ Name = "NotIn";           Operator = "NotIn";           Path = @("person", "department"); Check = '["HR","Finance"]' }
    @{ Name = "Like";            Operator = "Like";            Path = @("person", "name");       Check = "Jane*" }
    @{ Name = "NotLike";         Operator = "NotLike";         Path = @("person", "name");       Check = "John*" }
    @{ Name = "Match";           Operator = "Match";           Path = @("person", "name");       Check = "^Jane" }
    @{ Name = "NotMatch";        Operator = "NotMatch";        Path = @("person", "name");       Check = "^John" }
    @{ Name = "GreaterThan";     Operator = "GreaterThan";     Path = @("person", "age");        Check = 40 }
    @{ Name = "LessThan";        Operator = "LessThan";        Path = @("person", "age");        Check = 30 }
    @{ Name = "GreaterOrEqual";  Operator = "GreaterOrEqual";  Path = @("person", "age");        Check = 36 }
    @{ Name = "LessOrEqual";     Operator = "LessOrEqual";     Path = @("person", "age");        Check = 34 }
)


$missingPathCases = @(
    @{ Name = "Equals";         Operator = "Equals";         ShouldMatch = $false }
    @{ Name = "NotEquals";      Operator = "NotEquals";      ShouldMatch = $true  }

    @{ Name = "Contains";       Operator = "Contains";       ShouldMatch = $false }
    @{ Name = "NotContains";    Operator = "NotContains";    ShouldMatch = $true  }

    @{ Name = "In";             Operator = "In";             ShouldMatch = $false }
    @{ Name = "NotIn";          Operator = "NotIn";          ShouldMatch = $true  }

    @{ Name = "Like";           Operator = "Like";           ShouldMatch = $false }
    @{ Name = "NotLike";        Operator = "NotLike";        ShouldMatch = $true  }

    @{ Name = "Match";          Operator = "Match";          ShouldMatch = $false }
    @{ Name = "NotMatch";       Operator = "NotMatch";       ShouldMatch = $true  }

    @{ Name = "GreaterThan";    Operator = "GreaterThan";    ShouldMatch = $false }
    @{ Name = "LessThan";       Operator = "LessThan";       ShouldMatch = $false }
    @{ Name = "GreaterOrEqual"; Operator = "GreaterOrEqual"; ShouldMatch = $false }
    @{ Name = "LessOrEqual";    Operator = "LessOrEqual";    ShouldMatch = $false }
)


Describe "Invoke-StructMatcher" {
BeforeAll {
    $script:oldVerbosePreference = $VerbosePreference
    $script:oldInformationPreference = $InformationPreference
    $script:oldWarningPreference = $WarningPreference
    $script:oldProgressPreference = $ProgressPreference

    $VerbosePreference = 'SilentlyContinue'
    $InformationPreference = 'SilentlyContinue'
    $WarningPreference = 'Continue'
    $ProgressPreference = 'SilentlyContinue'

    Import-Module "$PSScriptRoot/../StructMatcher.psm1" -Force

    $hashtableData = @{
        person = @{
            department = "Finance"
            name       = "John Doe"
            type       = "employee"
            age        = 35
            roles      = @("Employee", "Approver")
            tags       = '["active","managed"]'
            address    = @{
                city = "Alkmaar"
            }
        }
    }

    $jsonData = '{
        "person": {
            "department": "Finance",
            "name": "John Doe",
            "type": "employee",
            "age": 35,
            "roles": ["Employee", "Approver"],
            "address": { "city": "Alkmaar" }
        }
    }'

    $customObjectData = $jsonData | ConvertFrom-Json

    $matchingRules = @(
        @{
            conditions = @(
                @{
                    path    = @("person", "department")
                    operator = "Equals"
                    check    = "Finance"
                }
                @{
                    path    = @("person", "type")
                    operator = "Equals"
                    check    = "employee"
                }
            )
            result = "Finance employees"
        }
        @{
            conditions = @(
                @{
                    path    = @("person", "department")
                    operator = "Equals"
                    check    = "IT"
                }
            )
            result = "IT employees"
        }
        @{
            conditions = @(
                @{
                    path    = @("person", "type")
                    operator = "Equals"
                    check    = "employee"
                }
            )
            result = "Employees"
        }
        @{
            conditions = @(
                @{
                    path    = @("person", "type")
                    operator = "Equals"
                    check    = "intern"
                }
            )
            result = "Interns"
        }
    )

    $defaultOperatorRule = @{
        conditions = @(
            @{
                path = @("person", "department")
                check = "Finance"
            }
        )
        result = "Default Equals"
    }

    $missingPropertyRule = @{
        conditions = @(
            @{
                path    = @("person", "manager", "department")
                operator = "Equals"
                check    = "Finance"
            }
        )
        result = "Unexpected match"
    }

    $invalidOperatorRule = @{
        conditions = @(
            @{
                path    = @("person", "department")
                operator = "Unknown"
                check    = "Finance"
            }
        )
        result = "Unexpected match"
    }

    $duplicateRules = @(
        @{
            conditions = @(@{
                path    = @("person", "department")
                operator = "Equals"
                check    = "Finance"
            })
            result = "Finance employees"
        }
        @{
            conditions = @(@{
                path    = @("person", "type")
                operator = "Equals"
                check    = "employee"
            })
            result = "Finance employees"
        }
        @{
            conditions = @(@{
                path    = @("person", "name")
                operator = "Equals"
                check    = "John Doe"
            })
            result = "John Doe result"
        }
    )
}

AfterAll {
    $VerbosePreference = $script:oldVerbosePreference
    $InformationPreference = $script:oldInformationPreference
    $WarningPreference = $script:oldWarningPreference
    $ProgressPreference = $script:oldProgressPreference
}

    It "matches multiple rules and returns all unique results" {
        $results = @(Invoke-StructMatcher -Rules $matchingRules -Data $hashtableData)

     $results | Should -HaveCount 2
        $results | Should -Contain "Finance employees"
        $results | Should -Contain "Employees"
    }

    It "returns unique results in first-match order" {
        $results = @(Invoke-StructMatcher -Rules $duplicateRules -Data $hashtableData)

        $results | Should -HaveCount 2
        $results[0] | Should -Be "Finance employees"
        $results[1] | Should -Be "John Doe result"
    }

    It "returns no results when no rule matches" {
        $results = @(Invoke-StructMatcher -Rules $matchingRules -Data @{ person = @{ department = "Sales" } })

        $results | Should -BeNullOrEmpty
    }

    It "requires every condition in a rule to match" {
        $results = @(Invoke-StructMatcher -Rules @($matchingRules[0]) -Data @{ person = @{ department = "Finance"; type = "intern" } })

        $results | Should -BeNullOrEmpty
    }

    It "matches a rule with an empty conditions collection" {
        $rules = @(
            @{
                conditions = @()
                result     = "Default result"
            }
        )

        $results = @(Invoke-StructMatcher -Rules $rules -Data $hashtableData)

        $results | Should -Be "Default result"
    }

    It "continues evaluating rules after a rule does not match" {
        $rules = @(
            @{
                conditions = @(
                    @{ path = @("person", "department"); operator = "Equals"; check = "Finance" }
                    @{ path = @("person", "type"); operator = "Equals"; check = "intern" }
                )
                result = "Wrong result"
            }
            @{
                conditions = @(
                    @{ path = @("person", "type"); operator = "Equals"; check = "employee" }
                )
                result = "Employees"
            }
        )

        $results = @(Invoke-StructMatcher -Rules $rules -Data $hashtableData)

        $results | Should -Be @("Employees")
    }

    It "supports hashtable, PSCustomObject, and JSON input" {
        $hashtableResults = @(Invoke-StructMatcher -Rules $matchingRules -Data $hashtableData)
        $objectResults = @(Invoke-StructMatcher -Rules $matchingRules -Data $customObjectData)
        $jsonResults = @(Invoke-StructMatcher -Rules $matchingRules -Data $jsonData)

        ($hashtableResults | ConvertTo-Json -Compress) | Should -Be ($objectResults | ConvertTo-Json -Compress)
        ($objectResults | ConvertTo-Json -Compress) | Should -Be ($jsonResults | ConvertTo-Json -Compress)
    }

    It "supports iterable rule collections such as ArrayList" {
        $ruleList = [System.Collections.ArrayList]::new()
        foreach ($rule in $matchingRules) {
            [void]$ruleList.Add($rule)
        }

        $results = @(Invoke-StructMatcher -Rules $ruleList -Data $hashtableData)

        $results | Should -HaveCount 2
        $results | Should -Contain "Finance employees"
        $results | Should -Contain "Employees"
    }

    It "supports dictionary implementations such as OrderedDictionary for data" {
        $orderedData = [ordered]@{
            person = [ordered]@{
                department = "Finance"
                name       = "John Doe"
                type       = "employee"
                age        = 35
                roles      = @("Employee", "Approver")
            }
        }

        $results = @(Invoke-StructMatcher -Rules $matchingRules -Data $orderedData)

        $results | Should -HaveCount 2
        $results | Should -Contain "Finance employees"
        $results | Should -Contain "Employees"
    }

    It "supports rules provided as JSON text" {
        $jsonRules = '[
            {
                "conditions": [
                    {
                        "path": ["person", "department"],
                        "operator": "Equals",
                        "check": "Finance"
                    },
                    {
                        "path": ["person", "type"],
                        "operator": "Equals",
                        "check": "employee"
                    }
                ],
                "result": "Finance employees"
            },
            {
                "conditions": [
                    {
                        "path": ["person", "type"],
                        "operator": "Equals",
                        "check": "employee"
                    }
                ],
                "result": "Employees"
            }
        ]'

        $results = @(Invoke-StructMatcher -Rules $jsonRules -Data $hashtableData)

        $results | Should -HaveCount 2
        $results | Should -Contain "Finance employees"
        $results | Should -Contain "Employees"
    }

    It "supports JSON-array values in data properties for membership checks" {
        $rule = @{
            conditions = @(
                @{ path = @("person", "tags"); operator = "Contains"; check = "active" }
            )
            result = "Has active tag"
        }

        $results = @(Invoke-StructMatcher -Rules @($rule) -Data $hashtableData)

        $results | Should -Be "Has active tag"
    }

    It "supports the default Equals operator" {
        $results = @(Invoke-StructMatcher -Rules @($defaultOperatorRule) -Data $hashtableData)

        $results | Should -Be "Default Equals"
    }

    It "supports missing intermediate properties without throwing" {
        $results = @(Invoke-StructMatcher -Rules @($missingPropertyRule) -Data $hashtableData)

        $results | Should -BeNullOrEmpty
    }

    It "supports operator <Name>" -ForEach $operatorCases {
        $rule = @{
            conditions = @(@{
                path    = $Path
                operator = $Operator
                check    = $Check
            })
            result = $Name
        }

        $results = @(Invoke-StructMatcher -Rules @($rule) -Data $hashtableData)

        $results | Should -Contain $Name
    }

    It "does not match operator <Name> for a negative check" -ForEach $operatorNegativeCases {
        $rule = @{
            conditions = @(@{
                path    = $Path
                operator = $Operator
                check    = $Check
            })
            result = $Name
        }

        $results = @(Invoke-StructMatcher -Rules @($rule) -Data $hashtableData)

        $results | Should -BeNullOrEmpty
    }

    It "throws for an unsupported operator" {
        { Invoke-StructMatcher -Rules @($invalidOperatorRule) -Data $hashtableData } |
            Should -Throw "Unsupported operator*"
    }

    It "throws when data input is an empty string" {
        { Invoke-StructMatcher -Rules $matchingRules -Data "" } |
            Should -Throw "Input cannot be an empty string.*"
    }

    It "throws when data input contains invalid JSON" {
        { Invoke-StructMatcher -Rules $matchingRules -Data "{ invalid json }" } |
            Should -Throw "Failed to parse JSON input*"
    }

    It "throws when rules input contains invalid JSON" {
        { Invoke-StructMatcher -Rules "{ invalid json }" -Data $hashtableData } |
            Should -Throw "Failed to parse JSON input*"
    }

    It "throws when rules input has an unsupported type" {
        { Invoke-StructMatcher -Rules 42 -Data $hashtableData } |
            Should -Throw "Unsupported input type*"
    }

    It "returns no results for an empty rules collection" {
        $results = @(Invoke-StructMatcher -Rules @() -Data $hashtableData)

        $results | Should -BeNullOrEmpty
    }

    It "does not modify the input data" {
        $before = $hashtableData | ConvertTo-Json -Depth 10 -Compress

        [void](Invoke-StructMatcher -Rules $matchingRules -Data $hashtableData)

        $after = $hashtableData | ConvertTo-Json -Depth 10 -Compress
        $after | Should -Be $before
    }

    It "does not modify the input rules" {
        $before = $matchingRules | ConvertTo-Json -Depth 10 -Compress

        [void](Invoke-StructMatcher -Rules $matchingRules -Data $hashtableData)

        $after = $matchingRules | ConvertTo-Json -Depth 10 -Compress
        $after | Should -Be $before
    }


    It "handles missing path for operator <Name>" -ForEach $missingPathCases {

        $rule = @{
            conditions = @(
                @{
                    path     = @("person", "doesNotExist")
                    operator = $Operator
                    check    = "whatever"
                }
            )
            result = $Name
        }

        $results = @(Invoke-StructMatcher -Rules @($rule) -Data $hashtableData)

        if ($ShouldMatch) {
            $results | Should -Contain $Name
        }
        else {
            $results | Should -BeNullOrEmpty
        }
    }

    It "supports dotted path notation" {

        $rule = @{
            conditions = @(
                @{
                    path     = "person.address.city"
                    operator = "Equals"
                    check    = "Alkmaar"
                }
            )
            result = "Match"
        }

        $results = @(Invoke-StructMatcher -Rules @($rule) -Data $hashtableData)

        $results | Should -Contain "Match"
    }
    It "distinguishes existing null values from missing properties" {

        $data = @{
            person = @{
                department = $null
            }
        }

        $rule = @{
            conditions = @(
                @{
                    path     = @("person","department")
                    operator = "Equals"
                    check    = $null
                }
            )
            result = "NullMatch"
        }

        $results = @(Invoke-StructMatcher -Rules @($rule) -Data $data)

        $results | Should -Contain "NullMatch"
    }
}




