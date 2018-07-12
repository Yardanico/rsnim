# RSNim

RSNim is a wrapper (both high-level and low-level) for the `LibRouter` library (it's not available in public, you should ask Stas'M to get a binary).

`LibRouter` (windows version) is a part of Router Scan - application to pentest different routers/switches/cameras.

All code in this repository is provided only for educational purposes.


# Usage

There are two examples in `tests` folder - `example.nim` and `rawexample.nim`.

First file shows an example on how to use high-level wrapper, second one shows
how to use low-level wrapper.

# Installation

You only need to run this if you want to use RSNim as a separate library

Navigate to the directory where you cloned this repo and run:
```
nimble install
```

# Requisites

- [Nim](https://nim-lang.org)