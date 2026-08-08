# Choosing the onboarding screens

Use the narrative shape, then select only the screens the product earns.

## Narrative sequence

| Phase | Candidate screen | Purpose | Keep when |
|---|---|---|---|
| Attract | Marketing welcome | Sell one product promise | The opening establishes quality and a clear reason to continue |
| Personalize | Name or identity | Personalize later copy | The value is visible later and the data is genuinely useful |
| Personalize | Desired outcome | Learn what success means | The choice configures the product or examples |
| Validate | Friction or pain points | Show understanding | Selections affect guidance, defaults, or messaging |
| Validate | Social proof | Increase confidence | Claims are truthful and relevant at this point |
| Demonstrate | Solution bridge | Connect pain to capability | A conceptual gap exists before the live demo |
| Personalize | Locale, units, or currency | Configure examples | Later screens and the app immediately reflect it |
| Demonstrate | Account or source setup | Introduce the data model | It is central and can be added or safely deferred |
| Demonstrate | Processing | Pace a meaningful transition | A brief pause connects setup to a result without faking work |
| Demonstrate | Product demo | Let the user perform a representative action | A real production component can show authentic value |
| Ask | Notifications or another permission | Explain value before the system prompt | The app has specific, useful permission-backed behavior |
| Ask | Paywall | Present the offer in context | Enough value has been demonstrated to justify the request |
| Deliver | Completion | Confirm personalization and hand off | The app is configured and ready to enter |

Do not preserve a screen merely because an older onboarding contained it.

## Screen contract

For every proposed screen, write:

- one communication goal;
- one success condition;
- primary action;
- optional secondary action and its exact semantics;
- required input or selection;
- state changed now versus committed at completion;
- how it affects a later screen or the product;
- analytics machine ID;
- scrolling and footer ownership;
- smallest-phone and landscape-iPad behavior.

Remove the screen if these answers are vague.

## Selection screens

Use substantial cards for choices that represent meaningful product statements.
Use chips for compact tags, filters, or dense optional attributes. A selection
card should have a clear icon, concise title, optional one-line explanation,
full-card hit target, selected trait, and non-color selected affordance.

For multi-select, use stable option IDs rather than localized text. Keep the CTA
disabled until the minimum valid count is reached. Avoid repetitive helper copy
when the disabled CTA and card state already explain the interaction.

## Locale-sensitive setup

Show the selected value as the visual focus and make the complete supported set
available. Propagate it immediately into later balances, measurements, prompts,
notifications, and offers. Never hard-code one symbol or unit into later screens.

## Copy hierarchy

Use one shared hierarchy across steps:

- short atmospheric eyebrow;
- promise-carrying headline;
- one or two concise supporting sentences;
- product-specific control or visual in the stage;
- one obvious primary action.

Write copy that survives expansion in long Latin languages, CJK localization,
and right-to-left layout. Never bake localized text into decorative artwork.
