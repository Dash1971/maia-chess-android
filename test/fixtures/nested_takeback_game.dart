// Reduced from the reported game; no player metadata is needed to reproduce it.
const nestedTakebackPrefix =
    '1. e4 e5 2. Nf3 Nc6 3. Nc3 Nf6 4. Bb5 d6 5. O-O Bg4 '
    '6. h3 Bh5 7. g4 Nxg4 8. hxg4 Bxg4 9. Bxc6+ bxc6 '
    '10. d3 h5 11. Bg5 Be7 12. Bxe7';

const nestedTakebackGame =
    '$nestedTakebackPrefix Qxe7 13. Qe2 Qd7 {Queen note} '
    '14. Qe3 {Reply note} *';

const duplicatedTakebackGame =
    '$nestedTakebackPrefix Qxe7 '
    '(12... Qxe7 13. Qe2 Qd7 {Queen note} 14. Qe3) '
    '(12... Qxe7 13. Qe2 Qd7 14. Qe3 {Reply note}) '
    '(12... Qxe7 13. Qe2 Qd7 {Queen note} 14. Qe3 {Reply note}) '
    '13. Kg2 *';
