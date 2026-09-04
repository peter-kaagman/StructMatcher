# StructMatcher

StructMatcher evaluates rule sets against nested data and returns matching results.

StructMatcher is a lightweight PowerShell rule engine for evaluating declarative rule sets against structured data.

It supports JSON, Hashtable and PSCustomObject input and returns matching results without imposing any opinion on how those results are used.

## Use Case

Typical usage is in HelloID-style provisioning flows:

1. Receive one person object as nested JSON data.
2. Evaluate that person against a JSON-defined ruleset.
3. Return one or more matching labels or targets (for example school, department, distribution list).

The module does not enforce what a result means. It only evaluates rules and returns matches, so scripts can apply those results to any downstream action.

## Design Note

StructMatcher is JSON-first for rule authoring, but object-compatible at runtime.

1. Author, store and version rule sets naturally.
2. Pass the same JSON directly to the module.
3. Reuse the module with already-converted PowerShell objects when needed.

## Conceptual Model

StructMatcher evaluates a RuleSet against input data.

A RuleSet contains one or more ConditionSets.

A ConditionSet contains zero or more Conditions and one Result.

A ConditionSet matches when all Conditions are met (AND logic).

When a ConditionSet matches, its Result is returned.

ConditionSets inside a RuleSet use implicit OR logic.

Multiple ConditionSets may return the same result value. Duplicate results are automatically removed. 

This makes it possible to express OR logic by defining multiple ConditionSets that return the same Result.

```
RuleSet
 ├─ ConditionSet
 │   ├─ Condition
 │   ├─ Condition
 │   └─ Result
 ├─ ConditionSet
 │   ├─ Condition
 │   └─ Result
 └─ ConditionSet
     └─ Result
```

## Public API

### Invoke-StructMatcher

Evaluates all rules against input data and returns unique matching results in insertion order.

This is the only public function in the module.

## Input Contract

### Rules

`-Rules` accepts:

1. Any iterable collection of rule objects (array, ArrayList, etc.)
2. JSON text representing one rule object or an array of rule objects

Each rule has:

1. `conditions` (optional): list of conditions
2. `result` (required): value returned when the rule matches

### Data

`-Data` accepts:

1. Traversable PowerShell structures (hashtable, PSCustomObject, ordered dictionary, arrays)
2. JSON text

## Rule Behavior

1. `Conditions` inside one `ConditionSet` use explicit AND logic.
2. `ConditionSets` inside one `RuleSet` use implicit OR logic.
3. If an `operator` is omitted, `Equals` is used.
4. An unknown operator throws an error.
5. Duplicate result values are returned once.

## missingOk

A path referenced by a condition may not exist in the input data. For negative operators, an absent path can be interpreted in two ways:

- The path is missing, so the negative condition is met.
- The path is missing, so the condition cannot be evaluated and is not met.

The optional `missingOk` property controls this behavior.

When `missingOk` is `true`, or when it is omitted, a negative condition is considered met if the path does not exist.

When `missingOk` is `false`, the path must exist for the negative condition to be met.

The flag `missingOk` only affects negative operators. Positive operators always require the path to exist to match.

The default value is `true`. Set `missingOk` to `false` to opt in to strict missing-path handling.

### Truth Table

| Path Exists | Operator Type | missingOk | Result |
|------------|---------------|-----------|--------|
| Yes | Positive | n/a | Evaluate condition |
| No  | Positive | n/a | False |
| Yes | Negative | True  | Evaluate condition |
| No  | Negative | True  | True |
| Yes | Negative | False | Evaluate condition |
| No  | Negative | False | False |

Positive operators:
- Equals
- Contains
- In
- Like
- Match
- GreaterThan
- LessThan
- GreaterOrEqual
- LessOrEqual

Negative operators:
- NotEquals
- NotContains
- NotIn
- NotLike
- NotMatch


## Catch-All Rules

A rule without conditions is considered a match and returns its `result`.

Use this as a fallback rule, typically at the end of your rule set.

## Condition Format

Each condition supports:

1. `path` (required): path as an array of keys or properties, or as a dot-separated string
2. `operator` (optional): comparison operator; defaults to `Equals`
3. `check` (required): value to compare against
4. `missingOk` (optional): controls missing-path behavior for negative operators; defaults to `true`

## Operator examples

### Equeals

Tests for exact equality.

```powershell:q
$data = @{ 
    person = @{ 
        department = "Finance" 
    } 
}
$ruleset = @{
    conditions = @(
        @{
            path     = @("person", "department")
            operator = "Equals"
            check    = "Finance"
        }
    )
    result = "Finance department"
}
Invoke-StructMatcher -Rules $rules -Data $data
# Returns: @('Finance department')
```
### NotEqueals

Tests for exact equality.

```powershell
$data = @{ 
    person = @{ 
        department = "Finance" 
    } 
}
$ruleset = @{
    conditions = @(
        @{
            path     = @("person", "department")
            operator = "NotEquals"
            check    = "Finance"
        }
    )
    result = "Not Finance department"
}
Invoke-StructMatcher -Rules $rules -Data $data
# Returns: @('Not Finance department')
```

| Operator | Purpose |
|---|---|
| Equals | exact equality |
| NotEquals | exact inequality |
| Contains | value contains check |
| NotContains | negated contains |
| In | value is in check-set |
| NotIn | value is not in check-set |
| Like | wildcard match |
| NotLike | negated wildcard match |
| Match | regex match |
| NotMatch | negated regex match |
| GreaterThan | greater than |
| LessThan | less than |
| GreaterOrEqual | greater than or equal |
| LessOrEqual | less than or equal |

Note for membership operators (`Contains`, `NotContains`, `In`, `NotIn`):

1. Arrays are used directly.
2. JSON array strings such as `"[\"a\",\"b\"]"` are parsed automatically.
3. Nested single-item arrays are flattened.

## Rule Examples

### Basic usage

```powershell
Import-Module ./StructMatcher.psm1 -Force

$data = @{
    person = @{
        department = "Finance"
        type       = "employee"
        name       = "John Doe"
    }
}
```

A RuleSet can contain a single ConditionSet like this:

```
$rules = @(
    @{
        conditions = @(
            @{ path = @("person", "department"); operator = "Equals"; check = "Finance" }
            @{ path = @("person", "type");       operator = "Equals"; check = "employee" }
        )
        result = "Finance employees"
    },
)

Invoke-StructMatcher -Rules $rules -Data $data
# Returns: Finance employees
```
Or multiple ConditionSets like this:

```powershell
$rules = @(
    @{
        conditions = @(
            @{ path = @("person", "department"); operator = "Equals"; check = "Finance" }
        )
        result = "Finance"
    },
    @{
        conditions = @(
            @{ path = @("person", "type"); operator = "Equals"; check = "employee" }
        )
        result = "Employees"
    },
    @{
        result = "Catch-All"
    }
)

Invoke-StructMatcher -Rules $rules -Data $data
# Returns: Finance, Employees, Catch-All
```

### JSON input

```powershell
$jsonRules = '[
  {
    "conditions": [
      { "path": ["person", "department"], "operator": "Equals", "check": "Finance" }
    ],
    "result": "Finance"
  }
]'

$jsonData = '{
  "person": {
    "department": "Finance"
  }
}

Invoke-StructMatcher -Rules $jsonRules -Data $jsonData

# Returns: Finance
```

## Errors

The module throws clear errors for contract violations and invalid input, including:

1. Empty string input
2. Invalid JSON input
3. Unsupported input types
4. Unsupported operators
5. Missing required condition properties (for example `path`)
6. Invalid rule definitions (for example `result = $null`)

## License

This project is licensed under the MIT License. See the LICENSE file for details.
