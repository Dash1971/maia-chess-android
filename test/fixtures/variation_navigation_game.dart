// User-reported move-16 navigation regression, including nested variations,
// an underpromotion, and a checkmate at the end of the main line.
const variationNavigationPgn = '''
[Event "Mobile Maia Game"]
[Site "Mobile Maia"]
[Date "2026.09.10"]
[Round "-"]
[White "Player"]
[Black "Maia-3 79M (1600)"]
[Result "1-0"]

1. e4 e5 2. d4 exd4 3. c3 dxc3 4. Bc4 cxb2 5. Bxb2 Nc6 6. Nf3 Nf6 7. O-O Bc5 8. e5 Ng4 9. Nc3 (9. Bxf7+ Kxf7 (9... Kf8 10. Bb3) 10. Qd5+ Ke8) 9... O-O 10. Qd2 Ngxe5 11. Nxe5 Nxe5 12. Bb3 d6 13. Na4 Bb6 14. Nxb6 axb6 15. f4 Nc6 16. f5 (16. Qc3 Qf6) 16... Ne5 17. f6 gxf6 18. Rf4 (18. Qh6 Ng4 19. Qh4 f5 20. Qg3 Qg5 21. Rae1) 18... Be6 19. Rh4 Ng6 20. Qh6 Nxh4 21. Bxf6 Qxf6 22. Qxf6 Bxb3 23. axb3 Rxa1+ 24. Qxa1 Re8 25. Qd4 Ng6 26. Kf2 Ne5 27. Qd5 Ng4+ 28. Kg3 Nf6 29. Qg5+ Kf8 30. Qxf6 Re3+ 31. Kf2 Rxb3 32. Qd8+ Kg7 33. Qxc7 Rb2+ 34. Kg3 Rb3+ 35. Kf4 Rb4+ 36. Ke3 Rb3+ 37. Kd4 Rb4+ 38. Kc3 Rg4 39. Qxb7 Rxg2 40. Qxg2+ Kf8 41. Qd5 Ke7 42. Kb4 Kd7 43. Kb5 Ke7 44. Kxb6 f6 45. Kc6 Kf8 46. Qxd6+ Kf7 47. Kd5 Kg6 48. Qg3+ Kf7 49. Ke4 h6 50. Kf5 Ke7 51. Qg6 Kd6 52. Qxh6 Kd5 53. Qxf6 Kc4 54. h4 Kd3 55. h5 Ke3 56. h6 Kf3 57. h7 Ke3 58. h8=R Kd3 59. Rh4 Ke3 60. Kg6 Kd3 61. Qf5+ Ke3 62. Re4+ Kd3 63. Qd5+ Kc3 64. Rc4+ Kb3 65. Qb5+ Ka3 66. Ra4# 1-0
''';
