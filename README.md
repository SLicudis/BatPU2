```
Specs:
-64 bytes of instruction cache
-4 stage pipeline: FETCH, DECODE, EXECUTE, WRITEBACK
-Classic harvard memory
-Uses the BatPU2 ISA, made by Mattbatwings: https://docs.google.com/spreadsheets/d/1Bj3wHV-JifR2vP4HRYoCWrdXYp3sGMG0Q58Nm56W4aI/edit?gid=0#gid=0
```
Pipeline diagram of the core:
![batpu2_pipeline](https://github.com/user-attachments/assets/d2ca48ab-e0b1-4e21-8a95-d0b6cb2b64ec)

RTL view of the core:
![image](https://github.com/user-attachments/assets/09773870-830c-4021-a296-2a5c4e9d8f49)
