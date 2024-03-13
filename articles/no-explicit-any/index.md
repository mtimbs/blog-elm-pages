---
{
    "title": "Removing explicit any from a TypeScript codebase",
    "description": "There are a surprising number of ways to explicitly rely on the any 'type' in TypeScript. Enough that it makes a search and delete not as trivial as you would think.",
    "image": "v1710252463/no-any-ts.png",
    "published": "2024-03-12",
}
---
Much has been [written](https://betterprogramming.pub/typescript-into-the-unknown-4c19d913cb15) about the `any` type (more of a type black hole than a type) and why the use of it is usually bad, yet many teams frequently adopt the use of `any` - especially when migrating a JavaScript codebase to TypeScript. At some point along that journey teams may want to remove the uses of `any` to more effectively leverage the safety that TypeScript provides. While they could just do a global search and replace and map `any` to `unknown` this usually isn't a viable strategy as this will cause an explosion of type errors in the code. Migrating from `any` to `unknown` will fail type checks even with strict mode off.

A much gentler approach is to remove the _explicit_ usage of `any` and let it fall through to an _implicit_ `any`. An _implicit_ `any` is how the TypeScript compiler will type something when it cannot _infer_ a type. You may be asking yourself, why is an _implicit any_ better than an _explicit any_? From a soundness point of view, it isn't. From a practical point of view, it lets you do some interesting things to help you ratchet up type safety. The explicit use of `any` can never result in a type error (because the compiler just ignores it), but you can configure the compiler to error on the usage of _implicit any_ by turning strict mode on or by setting `noImplicitAny: true` in your tsconfig.

If it is not obvious why this is useful, I highlight the challenges of adopting TypeScript on a non-trivial codebase here (coming soon).

## An Unexpected Puzzle
It turns out that _deleting all references of any_ is not as simple as you might assume. Even directly replacing `any` with `unknown` is not trivial (but certainly easier) as a blanket match on the word any may replace code comments, test descriptions etc.

You might assume that you could search for a pattern like `: any` and replace it with an empty string. However, consider what happens to the following function in this case

```typescript
const fn = (foo: any[]): any[] => foo;
const fn2 = (foo: any | undefined): any | undefined => foo;

// If we remove ": any" we get the following
const brokenFn = (foo[])[] => foo;
const brokenFn2 = (foo | undefined) | undefined => foo;
```
Then you also have things like aliases, generics, optional arguments and more to consider. A non-exhaustive list of some different usages of any:

```typescript
// standard usage
fn = (x: any): any => x;

// optionals 
fn = (x?: any) => x;
fn = (x?: any[]) => x;

// arrays
fn = (x: any[]) => x;
fn = (x: any[][]) => x;
fn = (x: any[][][]) => x;

// unions
fn = (x: any[] | undefined) => x;
fn = (x: any[] | null) => x;
fn = (x: any | undefined) => x;
fn = (x: any | null) => x;
fn = (x: any | string) => x;

// type alias
type DefinitelyNotAnAny = any;
const foo: DefinitelyNotAnAny = { good: "luck"};

// Generics
fn = async(): Promise<any> | void => { /** some code here */ };
fn = async(): Promise<any> | any => { /** some code here */ };
fn = async(): Promise<any>[] => { /** some code here */ };
fn = async(): Promise<any> => { /** some code here */ };
fn = async(): Promise<any | undefined> => { /** some code here */ };
fn = async(): Promise<any | null> => { /** some code here */ };
fn = async(): Promise<any[]> => { /** some code here */ };
fn = (x: Array<any>) => x;
fn = <any>() => { /** some code here */ };
fn = <any, any>() => { /** some code here */ };
fn = <any, any>() => { /** some code here */ };
fn = <any, any, any>() => { /** some code here */ };

// function types
type asyncFn = () => Promise<any>;
type asyncFn = () => Promise<any[]>;
type fn = () => any; 

// Other
const x = {} as any;
const xs = [] as any[];
```

I have a [Github repo](https://github.com/mtimbs/replace-explicit-any) that tackles this problem and includes a script, using `sed`, to go and delete as many different usage patterns of `any` that I could think of. The script as it stands looks something like this (but check the repo for live updates)

```bash
find . \( -name '*.tsx' -o -name '*.ts' \) -exec sed -i \
'
s/?: any\[\]/?/g;
s/: any\[\] | undefined//g;
s/: any\[\] | null//g;
s/= any;/= unknown;/g
s/: Promise<any> | void//g;
s/: Promise<any> | any//g;
s/: Promise<any>\[\]//g;
s/: Promise<any>//g;
s/=> Promise<any>/=> Promise<unknown>/g;
s/: Promise<any\[\]>//g;
s/=> Promise<any\[\];/=> Promise<unknown\[\]/g;
s/: Array<any>//g;
s/<any>//g;
s/<any\[\]>//g;
s/=> any;/=> unknown;/g;
s/<any | undefined>//g;
s/: any | undefined//g;
s/<any | null>//g;
s/: any | null//g;
s/: any | string//g;
s/?: any/?/g;
s/: any\[\]\[\]\[\]//g;
s/: any\[\]\[\]//g;
s/: any\[\]//g;
s/: any//g;
s/<any/<unknown/g;
s/, any,/, unknown,/g;
s/any>/unknown>/g;
s/ as any\[\]//g;
s/ as any//g;
' \
{} +
```
