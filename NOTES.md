# Lab 9 – One Cart, Four Ways: NOTES

## Part 1 – Shared code
**Why is `CartLine` immutable with `copyWith`?** Riverpod, Cubit and Bloc detect change by comparing the old and new state with `==`. If you mutate a list/field in place and re-assign it, old and new are the *same object*, so no notification is sent. Immutability also makes undo possible (old states stay intact in the history), makes equality cheap and correct, and lets the same pure helpers work in every style. Only `setState` "works" with mutation (it just marks the element dirty), which is the trap: the code can't be moved to another style, and any saved history entry silently changes when you mutate it.

**Why does `CartBody` take callbacks?** So it has no dependency on any state-management library: it is reused unchanged by all four pages, it is trivial to test/preview, and the style choice stays in one place (the page).

## Part 2 – setState
**T3: why would storing `total` be a bug?** A stored total is a second copy of data that is already derivable from `lines` + `coupon`. Any code path that changes lines or coupon and forgets to update `total` leaves the UI inconsistent. A getter can never go stale.

**T4: what happens without `if (!mounted) return;`?** If the user leaves the page during the 1.5 s checkout, the `State` is disposed. Calling `setState` (or using `context` for the SnackBar) afterwards throws "setState() called after dispose()" / uses a deactivated element.

**After T4, how would a second page (order history) read the cart?** It can't: the state is a private field of one `State` object. You would have to lift the state up to a common ancestor (or into an InheritedWidget/another solution) and pass it down, i.e. restructure the widget tree.

**Where does `_history` live; hot reload vs hot restart?** In the `State` object. Hot reload keeps the `State`, so cart and history survive. Hot restart re-runs `main`, creating a new `State`, so both are lost. Leaving the page also loses them.

## Part 3 – Riverpod
**Where `ref.read` / `ref.watch` are used (this implementation).**
`ref.watch`: (1) page – `cartProvider.select((lines, couponError))` to rebuild the list/coupon area; (2) `_Summary` – `select(s.summary)`; (3) `_UndoButton` – `canUndoProvider`; (4) `_CheckoutButton` – `select(submitting, enabled)`. All are display data, so they must subscribe.
`ref.read`: (1) page – `cartProvider.notifier` as a method handle for the callbacks; (2) inside the `ref.listen` callback to read the current state for the SnackBar/banner (one-off, inside a callback); (3) in the notifier `ref.read(checkoutApiProvider)` to get the API once; (4) `onPressed` of undo/checkout. None of these needs a rebuild.

**Why does the summary card rebuild less than in the setState version?** In setState the whole page rebuilds on any change. Here the card watches a `select` of only the summary values, so typing a wrong coupon (which changes only `couponError`) does not rebuild it (see the `debugPrint`).

**T2:** `state = state.copyWith(coupon: sameCode)` only notifies if `CartState` has value equality; with `==`/`hashCode` overridden the repeated identical state is ignored.

**T4: why is no `mounted` check needed?** The notifier lives in the `ProviderContainer`, not in a widget. It keeps working when the page is gone; widgets that are still listening are notified, and disposed widgets were already unsubscribed.

**T5 autoDispose:** with `NotifierProvider.autoDispose`, when the page is popped nothing listens, the notifier is disposed, and coming back builds a *new* notifier: cart and `_history` are empty again. The history is a field of the notifier instance, so it has the same lifetime as the provider.

## Part 4 – Cubit
**What breaks if `BlocProvider` is inside `CartBody`?** Only widgets *below* it can find the cubit. The page's `BlocBuilder`/`context.read` (above `CartBody`) would throw `ProviderNotFoundException`, and the AppBar's undo button couldn't see it either.

**Riverpod equivalents:** `BlocProvider` ↔ `NotifierProvider` (+ `ProviderScope`, or a nested `ProviderScope` for subtree scope); `BlocBuilder` ↔ `Consumer`/`ConsumerWidget` + `ref.watch`; `BlocListener` ↔ `ref.listen`; `context.read` ↔ `ref.read`; `buildWhen` ↔ `.select(...)`.

**T4:** `emit` after `close()` throws, hence `if (isClosed) return;`. **T5:** a getter on the cubit is not observable, so `canUndo` is part of `CartState`.

## Part 5 – Bloc
**When is the event layer worth it?** Worth it for checkout: a named `CartCheckoutRequested` event lets us add `droppable()` declaratively and the observer logs which event caused each transition. Pure overhead for the quantity stepper / coupon, which are trivial synchronous state updates where a Cubit method is shorter.

**Declarative "drop duplicate taps"?** Only Bloc (`transformer: droppable()`). In the others: guard manually (`if (state.status == submitting) return;`, which this project does), and disable the button while submitting.

**Observer:** `onChange` (Cubit and Bloc) shows `state -> state`; `onTransition` (Bloc only) adds the **event** that caused it.

**T5 – undoable events:** add / remove / qty change / coupon are undoable. Checkout (async side effect, status changes) and Undo itself are not. Encoded as an exhaustive `switch` in `isUndoable`.

## Checkpoint questions
1. **Where state lives / when it dies.** setState: in the `State` object, dies when the page leaves the tree. Riverpod: in the `ProviderContainer` (root `ProviderScope`), dies with the container (or when no listener remains for an autoDispose provider). Cubit: in the cubit created by `BlocProvider`, closed when that provider is disposed (page popped). Bloc: same as Cubit.
2. **Single public mutation API.** Notifier: its public methods (setting `state`). Cubit: its public methods (calling `emit`). Bloc: `add(event)`. setState has none: any code in the `State` can call `setState`.
3. **Mapping.** `ref.watch` ↔ `BlocBuilder`/`context.watch`; `ref.read` ↔ `context.read`; `ref.listen` ↔ `BlocListener`. `setState` is the lowest level: it rebuilds the widget that owns the state, with no separate subscribe/read/listen concepts.
4. **Why skip equal states, and what must `CartState` do?** To avoid pointless rebuilds/side effects. `CartState` must override `==` **and** `hashCode` (comparing every field, with lines compared by value, i.e. `CartLine`/`Product` also need `==`), or use Equatable.
5. **Guards after the `await`.** setState: `mounted` (State may be disposed). Riverpod: none (notifier isn't tied to a widget lifecycle). Cubit: `isClosed` (emit after close throws). Bloc: `emit.isDone` (handler's emitter is done once the bloc closes). They differ because each holder has a different lifetime owner.

## Comparison table
Lines = non-blank Dart lines in the style's folder (state holder + page, covers T1–T5); tests = lines in its test file.

| Style | LOC (T1–T5) | Test LOC | Files | Strength | Weakness |
|---|---|---|---|---|---|
| setState | 86 | 20 | 1 | Fewest concepts, no dependencies | State is trapped in the widget; logic only testable through widgets |
| Riverpod | 116 | 41 | 2 | Global, widget-independent state; `select`; tests without widgets | Must understand `watch` vs `read` vs `listen` |
| Cubit | 125 | 44 | 2 | Simple methods, `blocTest` asserts the emitted sequence | Scoped to the tree; getters not observable |
| Bloc | 171 | 65 | 3 | Traceable events, declarative concurrency (`droppable`) | Most boilerplate |
