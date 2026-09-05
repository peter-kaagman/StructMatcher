# StructMatcher

StructMatcher evaluates declarative rule sets against structured data and returns matching results.

It is designed to reduce large, difficult-to-maintain if/elseif chains by moving decision logic into data-driven rules. The module evaluates nested input against rule conditions and returns matching result values, while leaving downstream handling of those results to the caller.

It supports JSON, Hashtable, and PSCustomObject input for both rules and data.

## Function Synopsis

`Invoke-StructMatcher` evaluates a RuleSet against input data and returns matching results.

```powershell
$results = @(Invoke-StructMatcher -Rules $rules -Data $data)
```

### Input

- `Rules` - a RuleSet expressed as PowerShell objects or JSON
- `Data` - structured input data expressed as PowerShell objects or JSON

### Output

`Invoke-StructMatcher` returns an array of matching result values.

Each matching ConditionSet contributes its `result` value to the output collection.

Example:

```powershell
$rules = @(
    @{
        conditions = @(
            @{ path = "person.department"; check = "Finance" }
        )
        result = "Finance"
    },
    @{
        conditions = @(
            @{ path = "person.type"; check = "employee" }
        )
        result = "Employee"
    }
)
```

When both ConditionSets match:

```powershell
$results = @(Invoke-StructMatcher -Rules $rules -Data $data)
```

The returned array contains:

```powershell
@(
    "Finance"
    "Employee"
)
```

Duplicate result values are removed automatically while preserving insertion order.

If no ConditionSets match, an empty array is returned.


## Use Case

A typical use case is in HelloID-style provisioning flows:

1. Receive a person object as nested JSON data.
2. Evaluate that person against a JSON-defined ruleset.
3. Return one or more matching labels or targets, such as a school, department, or distribution list.

The module does not define what a result means. It only evaluates the rules and returns matches, so scripts can apply those results however they need downstream.

## Design Note

StructMatcher is JSON-first for rule authoring, but compatible with PowerShell objects at runtime.

1. Author, store, and version rulesets naturally.
2. Pass the same JSON directly to the module.
3. Reuse the module with already-converted PowerShell objects when needed.

## Conceptual Model

StructMatcher evaluates a RuleSet against input data.

A RuleSet contains one or more ConditionSets.

A ConditionSet contains zero or more Conditions and one Result.

A ConditionSet matches only when all Conditions are met (AND logic).

When a ConditionSet matches, its Result is returned.

ConditionSets within a RuleSet use implicit OR logic.

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


## Catch-All Rules

A rule without conditions is considered a match and returns its `result`. This acts as a catch-all rule.


## Condition Format

Each condition supports:

1. `path` (required): path as an array of keys or properties, or as a dot-separated string
2. `operator` (optional): comparison operator; defaults to `Equals`
3. `check` (required): value to compare against
4. `missingOk` (optional): controls missing-path behavior for negative operators; defaults to `true`

### Path

A `path` is a required property that specifies the location of a value in the input data. It can be defined either as an array of property names or as a dotted string. For example, given the following JSON input:

```json
{
  "person": {
    "department": "Finance",
    "type": "employee",
    "name": "John Doe"
  }
}
```

The person's department can be referenced as:
- `["person", "department"]` (array notation)
- `"person.department"` (dotted notation)

### Operator

The operator is optional and defaults to `Equals`. An unknown operator throws an error.

StructMatcher internally uses a set of standard PowerShell comparison operators. The following table lists the supported operators and their purpose.

| Operator | PowerShell | Purpose |
|---|---|---|
| Equals | -eq | Exact equality |
| NotEquals | -ne | Exact inequality |
| Contains | -contains | Check whether a value contains the target |
| NotContains | -notcontains | Check whether a value does not contain the target |
| In | -in | Check whether a value is in the target set |
| NotIn | -notin | Check whether a value is not in the target set |
| Like | -like | Wildcard match |
| NotLike | -notlike | Negated wildcard match |
| Match | -match | Regex match |
| NotMatch | -notmatch | Negated regex match |
| GreaterThan | -gt | Greater than |
| LessThan | -lt | Less than |
| GreaterOrEqual | -ge | Greater than or equal |
| LessOrEqual | -le | Less than or equal |

For details on PowerShell comparison operators, see [about_Comparison_Operators](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_comparison_operators).

Some operators like `Contains`, `NotContains`, `In` and `NotIn` use arrays on the left- or right-hand side. Check and data values are automatically converted to arrays when needed.

### Check

The `check` property is required and specifies the value to compare against.

### missingOk

A path referenced by a condition may not exist in the input data. For negative operators, an absent path can be interpreted in two ways:

- The path is missing, so the negative condition is met.
- The path is missing, so the condition cannot be evaluated and is not met.

The optional `missingOk` property controls this behavior.

When `missingOk` is `true`, or when it is omitted, a negative condition is considered met if the path does not exist. This makes `true` the default behavior for negative operators.

When `missingOk` is `false`, the path must exist for the negative condition to be met.

The flag `missingOk` only affects negative operators. Positive operators always require the path to exist to match.

The following table summarizes the behavior of `missingOk`:

| Path exists | Operator | missingOk | Match result |
|---|---|---:|---|
| Yes | Positive | n/a | Evaluate condition |
| No | Positive | n/a | False |
| Yes | Negative | true | Evaluate condition |
| No | Negative | true | True |
| Yes | Negative | false | Evaluate condition |
| No | Negative | false | False |

Positive operators are: Equals, Contains, In, Like, Match, GreaterThan, LessThan, GreaterOrEqual, and LessOrEqual.
Negative operators are: NotEquals, NotContains, NotIn, NotLike, and NotMatch.

## Rule Examples

The examples below build from the simplest case to more advanced evaluation logic. They are intentionally focused on concepts rather than a long list of operators.

For reuse, the following sample data is used in several examples:

```powershell
$data = @{
    person = @{
        department = "Finance"
        type       = "employee"
        name       = "John Doe"
        groups     = @("Finance", "Approvers", "IT-Operations")
        roles      = @("Employee", "Approver")
    }
}
```

### 1. Simple Match (Default Equals Operator)

A single condition and a single result. The default operator is `Equals`, and dotted-path notation is used here.

```powershell
$rules = @(
    @{
        conditions = @(
            @{ path = "person.department"; check = "Finance" }
        )
        result = "Finance team"
    }
)

$results = @(Invoke-StructMatcher -Rules $rules -Data $data)
```

Expected output:

```powershell
@(
    "Finance team"
)
```

### 2. AND Logic (Multiple Conditions in One ConditionSet)

All conditions in a single ConditionSet must match. This is the logical equivalent of AND.

```powershell
$rules = @(
    @{
        conditions = @(
            @{ path = @("person", "department"); operator = "Equals"; check = "Finance" }
            @{ path = @("person", "type");       operator = "Equals"; check = "employee" }
        )
        result = "Finance employee"
    }
)

$results = @(Invoke-StructMatcher -Rules $rules -Data $data)
```

Expected output:

```powershell
@(
    "Finance employee"
)
```

### 3. OR Logic (Multiple ConditionSets Returning the Same Result)

OR logic is achieved by defining multiple ConditionSets that return the same result value. In this example, both Department = Finance and Department = HR map to the same business result.

```powershell
$rules = @(
    @{
        conditions = @(
            @{ path = @("person", "department"); operator = "Equals"; check = "Finance" }
        )
        result = "Business Staff"
    },
    @{
        conditions = @(
            @{ path = @("person", "department"); operator = "Equals"; check = "HR" }
        )
        result = "Business Staff"
    }
)

$results = @(Invoke-StructMatcher -Rules $rules -Data $data)
```

Expected output:

```powershell
@(
    "Business Staff"
)
```

This demonstrates the rule model clearly: Finance OR HR => Business Staff. Duplicate result values are removed automatically.

### 4. Collection Matching (Contains vs In)

This example clarifies the semantic difference between `Contains` and `In`.

- `Contains` checks whether a collection contains a value.
- `In` checks whether a value is found in a collection.

```powershell
$rules = @(
    @{
        conditions = @(
            @{ path = "person.groups"; operator = "Contains"; check = "Approvers" }
        )
        result = "Group contains Approvers"
    },
    @{
        conditions = @(
            @{ path = "person.department"; operator = "In"; check = @("Finance", "HR") }
        )
        result = "Business department"
    }
)

$results = @(Invoke-StructMatcher -Rules $rules -Data $data)
```

Expected output:

```powershell
@(
    "Group contains Approvers"
    "Business department"
)
```

StructMatcher maps these operators to the corresponding PowerShell comparisons, but the important distinction is the direction of the comparison:

- `Contains`: collection contains value
- `In`: value is in collection

### 5. Missing Paths (`missingOk` Behavior)

Negative operators can treat a missing path as either a match or a failed evaluation, depending on `missingOk`.

```powershell
$data = @{
    person = @{
        department = "Finance"
    }
}

$rules = @(
    @{
        conditions = @(
            @{ path = "person.manager"; operator = "NotEquals"; check = "Finance"; missingOk = $true }
        )
        result = "missing manager is acceptable"
    },
    @{
        conditions = @(
            @{ path = "person.manager"; operator = "NotEquals"; check = "Finance"; missingOk = $false }
        )
        result = "missing manager is not acceptable"
    }
)

$results = @(Invoke-StructMatcher -Rules $rules -Data $data)
```

Expected output:

```powershell
@(
    "missing manager is acceptable"
)
```

With `missingOk = $true`, a missing path is treated as a match for negative operators. With `missingOk = $false`, the path must exist before the condition can match.

### 6. JSON Input (Rules and Data as JSON)

Rules and data can both be supplied as JSON. This example focuses on input format rather than rule logic.

```powershell
$jsonRules = @'
[
  {
    "conditions": [
      { "path": ["person", "department"], "operator": "Equals", "check": "Finance" }
    ],
    "result": "Finance"
  }
]
'@

$jsonData = @'
{
  "person": {
    "department": "Finance"
  }
}
'@

$results = @(Invoke-StructMatcher -Rules $jsonRules -Data $jsonData)
```

Expected output:

```powershell
@(
    "Finance"
)
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
