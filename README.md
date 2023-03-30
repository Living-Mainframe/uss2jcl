# uss2jcl
This script can be used to record an interactive shell session and store it as a JCL script using BPXBATCH.

## usage

```
./uss2jcl.sh
```
Use the shell, when you are finished, type `exit`. You will be prompted to review and save the session.

## Limitations
Not supported are:
- lines exceeding 70 characters
- recording interactive subshells
- automatically setting the environment
