# Patient import rules

Working notes: the decisions made after inspecting the sample CSV
(`test/fixtures/files/patients.csv`, 20 rows).

## The one rule

Every value in a row is one of three things:

- **Blank:** changes nothing. It is stored as empty on a new patient and never overwrites a stored value on an existing one.
- **Valid:** normalised to one stored format, then saved.
- **Malformed:** the whole row is rejected, with the reason recorded. Nothing from that row is saved.

There are no warnings. A row is either fully accepted or fully rejected.

The only fields that cannot be blank are the two identity fields and the first and last name.

## Who a patient is

A patient is identified by **health identifier province + health identifier** together. The same number in two different provinces is two different people.

Both fields are required. If either is blank or malformed, the row is rejected because the patient cannot be identified.

A unique database index on those two columns guarantees that a duplicate patient cannot be stored, even if two imports run at the same time.

## Field rules

Every value is trimmed first. A value that is empty after trimming is blank.

| Field | Blank allowed? | Normalisation | Malformed (rejects the row) |
|---|---|---|---|
| Health identifier | No | Kept as text, so `030` and `30` are different identifiers | Anything that is not digits only (for example `unknown`) |
| Health identifier province | No | Full name or code, any case, becomes the two-letter code (`Alberta`, `ab` become `AB`) | Not one of AB, BC, MB, NB, NL, NS, NT, NU, ON, PE, QC, SK, YT |
| Address province | Yes | Same as above | Not one of the 13 codes |
| First name, last name | No | Casing kept exactly as given | n/a |
| Middle name | Yes | Casing kept exactly as given | n/a |
| Address 1, address 2, city | Yes | Casing kept as given | n/a |
| Phone | Yes | Non-digits removed; a leading `1` is dropped from 11 digits; stored as 10 digits (`9025557890`) | Not exactly 10 digits after that |
| Email | Yes | Lowercased | Not a plausible address: one `@`, text on both sides, a dot in the domain, no spaces or characters such as `;` |
| Postal code | Yes | Spaces removed, uppercased, stored as `A1A 1A1` | Does not match letter-digit-letter digit-letter-digit |
| Date of birth | Yes | Stored as a date | Not a real calendar date in `YYYY-MM-DD` (for example `1989-28-04`); no guessing at swapped day and month. A date in the future is also rejected |
| Sex | Yes | Uppercased | Anything other than `M`, `F`, `NB`, `U`; a blank stays empty and does not become `U` |

Email and phone are both optional; there is no rule requiring at least one contact method.

A postal code that does not match the address province is accepted; it is not checked.

## What happens to each row

Each row ends in exactly one outcome:

| Outcome | Meaning |
|---|---|
| Created | A new patient |
| Updated | An existing patient, and at least one stored value changed |
| Unchanged | An existing patient, and every non-blank value already matches what is stored |
| Rejected | At least one problem; the CSV line number, the column and the reason are recorded for every problem in the row |

- **Comparison uses normalised values**, so `T2P1M9` and `T2P 1M9` count as the same.
- **A change in casing only** (`Smith` to `SMITH`) counts as an update, because names are stored as given.
- **Accept or reject depends only on the file**, never on what is already stored.

## Behaviour on repeat data

| Situation | Result |
|---|---|
| Existing patient, different values | The new non-blank values overwrite the stored ones; counted as updated |
| Blank where a value is stored | The stored value is kept; blanks never erase data |
| Same patient twice in one file | The first row is used; each later row is rejected as "duplicate of line N" |
| Same file uploaded twice | The second upload reports every accepted row as unchanged |
| Fixing a rejection | The clinic corrects the row and uploads again; imported rows come back unchanged and the fixed row is created |

Letting the last row win for in-file duplicates was dropped because it breaks idempotency: if the two rows differ, every re-upload would flip the patient to the first row's values and back, reporting two updates each time.

## Whole-file failures and counts

- **The whole file is refused**, with one message and no rows written, when it is not a readable CSV, has no data rows, or is missing an expected column header.
- **Processed** is the number of data rows, and always equals created + updated + unchanged + rejected.
- Blank lines are skipped and not counted; extra columns are ignored.

## Expected result for the sample file (20 rows)

**First upload:** 20 processed, 16 created, 4 rejected.

| CSV line | Patient | Reason rejected |
|---|---|---|
| 4 | Health identifier 12 | Date of birth `1989-28-04` is not a real date |
| 10 | Health identifier `unknown` | Health identifier is not a number |
| 19 | Health identifier 5, Alberta | Email ends in `;` |
| 21 | Health identifier `unknown` | Health identifier is not a number |

The two rows with health identifier 5 (line 6 in BC, line 19 in Alberta) are different people.

**Second upload of the same file:** 20 processed, 16 unchanged, 4 rejected.

## Why these rules

- **Patient records must be correct, not just complete.** Silently dropping a bad email means the clinic believes it uploaded data that it did not. Rejecting tells them immediately and exactly what to fix.
- **Rejection is cheap because re-uploading is safe.** A fixed file only creates what was missing.
- **One rule for every field** is easier to explain, build and test than a list of exceptions.
- **The "at least one contact" rule was dropped** because, with blanks never erasing, the same row could pass or fail depending on what the database already held.

Why the individual field rules:

- **Province codes:** spelling variants (`Alberta`, `AB`) must match the same patient, so identity needs one form.
- **Phone digits, postal spacing, uppercase sex:** these fix format, not meaning, and give one stored form so that re-uploads compare correctly.
- **Lowercase email:** addresses are case-insensitive in practice, so case alone should not count as a change.
- **No guessing on dates:** swapping day and month could silently store a wrong birth date.
- **Blank sex is not `U`:** `U` is a recorded answer ("unknown"); turning blanks into `U` would invent data and let a blank overwrite a stored value.
- **Name casing kept:** changing `McDonald` or `van der Berg` would damage real names.
- **No postal code versus province check:** a mismatch is not malformed data, and 12 of the 16 accepted sample rows have one.

## Trade-offs and limitations

- **A messy export will see more rejected rows on the first upload.** Warnings could be added later if real clinics need them.
- **An import cannot clear a stored value**, because blanks never erase.
- **Digits-only health identifiers** would reject Quebec health numbers, which contain letters. Supporting them needs per-province rules.

## Decided against

- **External address validation APIs:** they would send patient data to a third party, add a failure point, and need API keys.
- **Identifying patients by name, date of birth or phone:** those values change, which would create duplicates.
- **Correcting malformed values by guessing.**
