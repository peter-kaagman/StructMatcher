Import-Module "$PSScriptRoot/StructMatcher.psm1" -Force

$rules = @(
    @{
        conditions = @(
            @{
                level    = @("person","department")
                operator = "Equals"
                check    = "Finance"
            }
            @{
                level    = @("person","type")
                operator = "Equals"
                check    = "employee"
            }
        )
        result = "Finance department"
    }

    @{
        conditions = @(
            @{
                level    = @("person","department")
                operator = "Equals"
                check    = "IT"
            }
            @{
                level    = @("person","type")
                operator = "Equals"
                check    = "employee"
            }
        )
        result = "IT department"
    }

    @{
        conditions = @(
            @{
                level    = @("person","type")
                operator = "Equals"
                check    = "employee"
            }
        )
        result = "Employees"
    }

    @{
        conditions = @(
            @{
                level    = @("person","type")
                operator = "Equals"
                check    = "intern"
            }
        )
        result = "Interns"
    }
)


$person1 = @{
    person = @{
        department = "Finance"
        name       = "John Intern"
        type       = "Intern"
    }
}

$person2 = @{
    person = @{
        department = "Finance"
        name       = "John Employee"
        type       = "employee"
    }
}

$results = @( Invoke-StructMatcher -Rules $rules -Data $person1)
Write-Host "Result for person1: $results"

$results = @( Invoke-StructMatcher -rules $rules -data $person2 )
Write-Host "Result for person2: $results"