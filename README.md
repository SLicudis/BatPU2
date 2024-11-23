
Specs: <br>
-64 bytes of instruction cache <br>
-4 stage pipeline: FETCH, DECODE, EXECUTE, WRITEBACK <br>
-Classic harvard memory <br>
-Uses the BatPU2 ISA, made by Mattbatwings: https://docs.google.com/spreadsheets/d/1Bj3wHV-JifR2vP4HRYoCWrdXYp3sGMG0Q58Nm56W4aI/edit?gid=0#gid=0 <br>

Pipeline diagram of the core:
![batpu2_pipeline](https://github.com/user-attachments/assets/d2ca48ab-e0b1-4e21-8a95-d0b6cb2b64ec)

RTL view of the core: (Yellow is fetch, purple is decode, red is execute, orange is writeback)
![highlighted RTL](https://github.com/user-attachments/assets/076da8a2-10c3-4b58-b82d-f185674d7f02)



