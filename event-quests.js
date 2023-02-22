'use strict';

const x = [
  {
    "uid": 1872
  },
  {
    "uid": 1873,
    "requirements": [1872]
  },
  {
    "uid": 1874,
    "requirements": [1872]
  },
  {
    "uid": 1875,
    "requirements": [1874]
  },
  {
    "uid": 1876,
    "requirements": [1875]
  },
  {
    "uid": 1877,
    "requirements": [1876]
  },
  {
    "uid": 1878,
    "requirements": [1876]
  },
  {
    "uid": 1879,
    "requirements": [1878, 1874]
  },
  {
    "uid": 1880,
    "requirements": [1878]
  },
  {
    "uid": 1881,
    "requirements": [1878]
  },
  {
    "uid": 1882,
    "requirements": [1880]
  },
  {
    "uid": 1883,
    "requirements": [1882]
  },
  {
    "uid": 1884,
    "requirements": [1883]
  },
  {
    "uid": 1885,
    "requirements": [1879]
  },
  {
    "uid": 1886,
    "requirements": [1879]
  },
  {
    "uid": 1887,
    "requirements": [1883, 1886]
  },
  {
    "uid": 1888,
    "requirements": [1886]
  },
  {
    "uid": 1889,
    "requirements": [1888]
  },
  {
    "uid": 1890,
    "requirements": [1885, 1889]
  },
  {
    "uid": 1891,
    "requirements": [1887, 1888]
  },
  {
    "uid": 1892,
    "requirements": [1879]
  },
  {
    "uid": 1893,
    "requirements": [1887]
  },
  {
    "uid": 1894,
    "requirements": [1887]
  },
  {
    "uid": 1895,
    "requirements": [1889, 1891]
  },
  {
    "uid": 1896,
    "requirements": [1895]
  },
  {
    "uid": 1897,
    "requirements": [1895]
  },
  {
    "uid": 1898,
    "requirements": [1895]
  },
  {
    "uid": 1899,
    "requirements": [1898]
  },
  {
    "uid": 1900,
    "requirements": [1899]
  },
  {
    "uid": 1901,
    "requirements": [1900, 1895]
  },
  {
    "uid": 1902,
    "requirements": [1901]
  },
  {
    "uid": 1903,
    "requirements": [1902]
  },
  {
    "uid": 1904,
    "requirements": [1903]
  },
  {
    "uid": 1905,
    "requirements": [1904, 1901]
  },
  {
    "uid": 1906,
    "requirements": [1905]
  },
  {
    "uid": 1907,
    "requirements": [1905]
  },
  {
    "uid": 1908,
    "requirements": [1905]
  },
  {
    "uid": 1909,
    "requirements": [1905]
  },
  {
    "uid": 1910,
    "requirements": [1907]
  },
  {
    "uid": 1911,
    "requirements": [1907]
  },
  {
    "uid": 1912,
    "requirements": [1911, 1905]
  },
  {
    "uid": 1913,
    "requirements": [1912]
  },
  {
    "uid": 1914,
    "requirements": [1911]
  },
  {
    "uid": 1915,
    "requirements": [1914]
  },
  {
    "uid": 1916,
    "requirements": [1915]
  },
  {
    "uid": 1917,
    "requirements": [1916, 1914]
  },
  {
    "uid": 1918,
    "requirements": [1915]
  },
  {
    "uid": 1919,
    "requirements": [1918, 1917]
  },
  {
    "uid": 1920,
    "requirements": [1911]
  },
  {
    "uid": 1921,
    "requirements": [1920, 1912]
  },
  {
    "uid": 1922,
    "requirements": [1921]
  },
  {
    "uid": 1923,
    "requirements": [1922]
  },
  {
    "uid": 1924,
    "requirements": [1922]
  },
  {
    "uid": 1925,
    "requirements": [1922]
  },
  {
    "uid": 1926,
    "requirements": [1923]
  },
  {
    "uid": 1927,
    "requirements": [1923]
  },
  {
    "uid": 1928,
    "requirements": [1927]
  },
  {
    "uid": 1929,
    "requirements": [1921]
  },
  {
    "uid": 1930,
    "requirements": [1921]
  },
  {
    "uid": 1931,
    "requirements": [1921]
  },
  {
    "uid": 1932,
    "requirements": [1921, 1930]
  },
  {
    "uid": 1933,
    "requirements": [1921]
  },
  {
    "uid": 1934,
    "requirements": [1933]
  },
  {
    "uid": 1935,
    "requirements": [1934]
  },
  {
    "uid": 1936,
    "requirements": [1935]
  },
  {
    "uid": 1937,
    "requirements": [1936]
  },
  {
    "uid": 1938,
    "requirements": [1937, 1921]
  },
  {
    "uid": 1939,
    "requirements": [1938]
  },
  {
    "uid": 1940,
    "requirements": [1938]
  },
  {
    "uid": 1941,
    "requirements": [1940]
  },
  {
    "uid": 1942,
    "requirements": [1941]
  },
  {
    "uid": 1943,
    "requirements": [1941]
  },
  {
    "uid": 1944,
    "requirements": [1941]
  },
  {
    "uid": 1945,
    "requirements": [1944, 1938]
  },
  {
    "uid": 1946,
    "requirements": [1944]
  },
  {
    "uid": 1947,
    "requirements": [1945]
  },
  {
    "uid": 1948,
    "requirements": [1947]
  },
  {
    "uid": 1949,
    "requirements": [1947]
  },
  {
    "uid": 1950,
    "requirements": [1945]
  },
  {
    "uid": 1951,
    "requirements": [1945]
  },
  {
    "uid": 1952,
    "requirements": [1945]
  },
  {
    "uid": 1953,
    "requirements": [1952]
  },
  {
    "uid": 1954,
    "requirements": [1953]
  },
  {
    "uid": 1955,
    "requirements": [1953]
  },
  {
    "uid": 1956,
    "requirements": [1952]
  },
  {
    "uid": 1957,
    "requirements": [1956, 1952]
  },
  {
    "uid": 1958,
    "requirements": [1957]
  },
  {
    "uid": 1959,
    "requirements": [1958]
  },
  {
    "uid": 1960,
    "requirements": [1959]
  },
  {
    "uid": 1961,
    "requirements": [1960]
  },
  {
    "uid": 1962,
    "requirements": [1961]
  },
  {
    "uid": 1963,
    "requirements": [1962, 1957]
  },
  {
    "uid": 1964,
    "requirements": [1963]
  },
  {
    "uid": 1965,
    "requirements": [1964]
  },
  {
    "uid": 1966,
    "requirements": [1964]
  },
  {
    "uid": 1967,
    "requirements": [1964]
  },
  {
    "uid": 1968,
    "requirements": [1967, 1963]
  },
  {
    "uid": 1969,
    "requirements": [1968]
  },
  {
    "uid": 1970,
    "requirements": [1969]
  },
  {
    "uid": 1971,
    "requirements": [1968]
  },
  {
    "uid": 1972,
    "requirements": [1968]
  },
  {
    "uid": 1973,
    "requirements": [1972]
  },
  {
    "uid": 1974,
    "requirements": [1973]
  },
  {
    "uid": 1975,
    "requirements": [1974, 1968]
  },
  {
    "uid": 1976,
    "requirements": [1975]
  },
  {
    "uid": 1977,
    "requirements": [1976]
  },
  {
    "uid": 1978,
    "requirements": [1977]
  },
  {
    "uid": 1979,
    "requirements": [1978]
  },
  {
    "uid": 1980,
    "requirements": [1979, 1975]
  },
  {
    "uid": 1981,
    "requirements": [1980]
  },
  {
    "uid": 1982,
    "requirements": [1981]
  },
  {
    "uid": 1983,
    "requirements": [1982]
  },
  {
    "uid": 1984,
    "requirements": [1983]
  },
  {
    "uid": 1985,
    "requirements": [1984, 1980]
  }
];

for (const a of x) {
  if (a.requirements) {
    for (const b of a.requirements) {
      console.log(`${b} -> ${a.uid}`);
    }
  }
}

// https://dreampuf.github.io/GraphvizOnline/

/*
strict digraph {
    1872 -> 1873
    1872 -> 1874
    1874 -> 1875
    1875 -> 1876
    1876 -> 1877
    1876 -> 1878
    1878 -> 1879
    1874 -> 1879
    1878 -> 1880
    1878 -> 1881
    1880 -> 1882
    1882 -> 1883
    1883 -> 1884
    1879 -> 1885
    1879 -> 1886
    1883 -> 1887
    1886 -> 1887
    1886 -> 1888
    1888 -> 1889
    1885 -> 1890
    1889 -> 1890
    1887 -> 1891
    1888 -> 1891
    1879 -> 1892
    1887 -> 1893
    1887 -> 1894
    1889 -> 1895
    1891 -> 1895
    1895 -> 1896
    1895 -> 1897
    1895 -> 1898
    1898 -> 1899
    1899 -> 1900
    1900 -> 1901
    1895 -> 1901
    1901 -> 1902
    1902 -> 1903
    1903 -> 1904
    1904 -> 1905
    1901 -> 1905
    1905 -> 1906
    1905 -> 1907
    1905 -> 1908
    1905 -> 1909
    1907 -> 1910
    1907 -> 1911
    1911 -> 1912
    1905 -> 1912
    1912 -> 1913
    1911 -> 1914
    1914 -> 1915
    1915 -> 1916
    1916 -> 1917
    1914 -> 1917
    1915 -> 1918
    1918 -> 1919
    1917 -> 1919
    1911 -> 1920
    1920 -> 1921
    1912 -> 1921
    1921 -> 1922
    1922 -> 1923
    1922 -> 1924
    1922 -> 1925
    1923 -> 1926
    1923 -> 1927
    1927 -> 1928
    1921 -> 1929
    1921 -> 1930
    1921 -> 1931
    1921 -> 1932
    1930 -> 1932
    1921 -> 1933
    1933 -> 1934
    1934 -> 1935
    1935 -> 1936
    1936 -> 1937
    1937 -> 1938
    1921 -> 1938
    1938 -> 1939
    1938 -> 1940
    1940 -> 1941
    1941 -> 1942
    1941 -> 1943
    1941 -> 1944
    1944 -> 1945
    1938 -> 1945
    1944 -> 1946
    1945 -> 1947
    1947 -> 1948
    1947 -> 1949
    1945 -> 1950
    1945 -> 1951
    1945 -> 1952
    1952 -> 1953
    1953 -> 1954
    1953 -> 1955
    1952 -> 1956
    1956 -> 1957
    1952 -> 1957
    1957 -> 1958
    1958 -> 1959
    1959 -> 1960
    1960 -> 1961
    1961 -> 1962
    1962 -> 1963
    1957 -> 1963
    1963 -> 1964
    1964 -> 1965
    1964 -> 1966
    1964 -> 1967
    1967 -> 1968
    1963 -> 1968
    1968 -> 1969
    1969 -> 1970
    1968 -> 1971
    1968 -> 1972
    1972 -> 1973
    1973 -> 1974
    1974 -> 1975
    1968 -> 1975
    1975 -> 1976
    1976 -> 1977
    1977 -> 1978
    1978 -> 1979
    1979 -> 1980
    1975 -> 1980
    1980 -> 1981
    1981 -> 1982
    1982 -> 1983
    1983 -> 1984
    1984 -> 1985
    1980 -> 1985
}
*/
