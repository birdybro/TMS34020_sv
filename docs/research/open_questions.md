# Open research questions

| ID | Question | Impact | Next evidence |
|---|---|---|---|
| OQ-0001 | What are the exact package top markings/date codes on production Battletoads boards? | Selects original versus A-revision timing | High-resolution board photo with readable GSP marking |
| OQ-0002 | What are the exact package top markings/date codes on Revolution X board revisions? | Selects original versus A-revision timing | High-resolution board photos correlated with 5770-13534 revisions |
| OQ-0003 | Was a standalone SMJ34020 (non-A) released, and how did it differ from commercial TMS34020? | Device matrix and revision selector | Original TI military data sheet/order catalog |
| OQ-0004 | Is there a separate SMJ34020A versus SM34020A functional errata set? | Military/high-reliability behavior | TI errata/qualification publications |
| OQ-0005 | What is the publication number and latest revision of TMS34020/TMS34020A silicon errata? | Architectural/timing correctness | TI archive/catalog or paper scan |
| OQ-0006 | What revisions and content deltas distinguish the SPVU004 and SPVU020 code-generation tool guides? | Assembler/COFF syntax | Title/copyright pages and tables of contents for both identifiers |
| OQ-0007 | Which documented instruction-cycle cases vary with cache, overlap, bus size, page mode and A clock stretch? | Cycle-accuracy plan | Chapter 5/8/13/14 extraction into timing database |
| OQ-0008 | Does either target game enable CONFIG.CSE clock stretch? | Board timing and default variant | Device marking plus boot-code/local-ROM trace |
| OQ-0009 | What are the cache refill interrupt checkpoint, `SIZE16` pin schedule, reset-time SSA-match, exact local-bus phases, and saved CPU continuation words? | Cache RTL, bus traces, fault return, and sequencer timing | User's Guide chapters 6, 8, 13–15; data-sheet timing figures; errata; hardware traces |
| OQ-0010 | Does any primary source expose additional internal pipeline stages, speculative fetch cancellation, or branch-prefetch rules beyond the overlap and ordering statements in §§5.3/5.5? | Cycle model and redirect recovery | TI patents, later guide revisions, XDS documentation, diagnostics, and hardware traces |
| OQ-0011 | Did another TMS34020 User's Guide revision or erratum correct the TRAPL p.13-256 vector-address prose to match Figures 6-1/13-13 and the examples? | Confirms the implemented signed trap-vector formula | Other guide revisions, TI errata, diagnostic software, or hardware trace |
| OQ-0012 | What exact read/write decomposition, overlap result, interrupt checkpoint, dynamic-width behavior, page sequence, and fault/retry ordering does each BLMOVE S/D mode use? | BLMOVE timing, continuation, bus traces, and retry idempotence | TI diagnostics, patents/other guide revisions, XDS traces, or physical bus capture |
| OQ-0013 | Which remaining `CcodeXXh` words are legal short `JRcc` hardware encodings, given exact long `Ccode00h`, exact JAcc `Ccode80h`, and the TMS34020 guide's conflicting “±128” assembler-range text recorded in RSC-0020? | Collision-free short conditional-jump decode, exhaustive opcode classification, and illegal-word policy | Other guide revisions, TI assembler diagnostics/listings, silicon tests, or TI decode patents |
