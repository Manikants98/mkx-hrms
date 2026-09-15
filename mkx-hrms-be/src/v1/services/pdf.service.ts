const pdfmake = require("pdfmake");

/** Standard PDF fonts without TTF */
const fonts = {
  Helvetica: {
    normal: "Helvetica",
    bold: "Helvetica-Bold",
    italics: "Helvetica-Oblique",
    bolditalics: "Helvetica-BoldOblique",
  },
};

pdfmake.fonts = fonts;

/** UI Palette matches HRMS */
const COLOR = {
  ink: "#16233a",
  inkSoft: "#4a5a72",
  muted: "#8b9199",
  line: "#e0e4e2",
  lineStrong: "#c7cdc9",
  teal: "#1f6e5c",
  tealBg: "#e6f0ec",
  brick: "#a13d2f",
  brickBg: "#f6e9e6",
  gold: "#9c6f1f",
  goldBg: "#f6efdf",
  paper: "#eef1ef",
};

/**
 * Parses numeric amount
 */
const parseAmt = (val: string | number | undefined) =>
  Number(String(val || 0).replace(/[^0-9.-]+/g, "")) || 0;

/**
 * Format currency
 */
const formatCurrency = (val: number) =>
  "₹" +
  val.toLocaleString("en-IN", {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  });

/**
 * Converts a whole rupee amount into words, Indian numbering (lakh/crore).
 */
const numberToWords = (num: number): string => {
  const ones = [
    "",
    "one",
    "two",
    "three",
    "four",
    "five",
    "six",
    "seven",
    "eight",
    "nine",
    "ten",
    "eleven",
    "twelve",
    "thirteen",
    "fourteen",
    "fifteen",
    "sixteen",
    "seventeen",
    "eighteen",
    "nineteen",
  ];
  const tens = [
    "",
    "",
    "twenty",
    "thirty",
    "forty",
    "fifty",
    "sixty",
    "seventy",
    "eighty",
    "ninety",
  ];

  const two = (n: number): string =>
    n < 20 ? ones[n] : tens[Math.floor(n / 10)] + (n % 10 ? " " + ones[n % 10] : "");
  const three = (n: number): string =>
    (n >= 100 ? ones[Math.floor(n / 100)] + " hundred " : "") + two(n % 100);

  let n = Math.round(num);
  if (n === 0) return "zero";

  const parts: string[] = [];
  const crore = Math.floor(n / 10000000);
  n %= 10000000;
  const lakh = Math.floor(n / 100000);
  n %= 100000;
  const thousand = Math.floor(n / 1000);
  n %= 1000;

  if (crore) parts.push(`${three(crore)} crore`);
  if (lakh) parts.push(`${three(lakh)} lakh`);
  if (thousand) parts.push(`${three(thousand)} thousand`);
  if (n) parts.push(three(n));

  return parts.join(" ").trim();
};

const titleCase = (s: string) => s.charAt(0).toUpperCase() + s.slice(1);

const MONTH_NAMES = [
  "January",
  "February",
  "March",
  "April",
  "May",
  "June",
  "July",
  "August",
  "September",
  "October",
  "November",
  "December",
];

export interface PayslipData {
  id: string;
  month: number;
  year: number;
  payDate: string;
  status: string;
  employeeName: string;
  employeeId: string;
  department: string;
  designation: string;
  grossPay: number;
  totalDeductions: number;
  netPay: number;
  earnings: Array<{ name: string; amount: number }>;
  deductions: Array<{ name: string; amount: number }>;
}

const tableLayout = {
  hLineWidth: (i: number, node: any) => (i === 0 || i === node.table.body.length ? 1 : 0.5),
  vLineWidth: () => 0,
  hLineColor: () => COLOR.line,
  paddingLeft: () => 0,
  paddingRight: () => 0,
};

const earningsOrDeductionsTable = (
  heading: string,
  rows: Array<{ name: string; amount: number }>,
  total: number,
  accentColor: string,
  emptyLabel: string,
) => ({
  stack: [
    {
      text: heading,
      fontSize: 8.5,
      bold: true,
      color: COLOR.muted,
      characterSpacing: 0.4,
      margin: [0, 0, 0, 10] as [number, number, number, number],
    },
    {
      table: {
        widths: ["*", "auto"],
        body:
          rows.length > 0
            ? rows.map((r) => [
                { text: r.name, fontSize: 10, margin: [0, 6, 0, 6] },
                {
                  text: formatCurrency(parseAmt(r.amount)),
                  fontSize: 10,
                  bold: true,
                  color: accentColor,
                  alignment: "right",
                  margin: [0, 6, 0, 6],
                },
              ])
            : [
                [
                  {
                    text: emptyLabel,
                    colSpan: 2,
                    italics: true,
                    color: COLOR.muted,
                    fontSize: 9.5,
                    alignment: "center",
                    margin: [0, 10, 0, 10],
                  },
                  "",
                ],
              ],
      },
      layout: tableLayout,
    },
    {
      columns: [
        { text: `Total ${heading.toLowerCase()}`, fontSize: 9.5, bold: true, color: COLOR.ink },
        {
          text: formatCurrency(total),
          fontSize: 9.5,
          bold: true,
          alignment: "right",
          color: COLOR.ink,
        },
      ],
      margin: [0, 8, 0, 0] as [number, number, number, number],
      columnGap: 0,
    },
  ],
});

export const generatePayslipPdf = (data: PayslipData): Promise<Buffer> => {
  return new Promise((resolve, reject) => {
    try {
      const gross = parseAmt(data.grossPay);
      const totalDeductions = parseAmt(data.totalDeductions);
      const net = parseAmt(data.netPay);
      const netWords = titleCase(numberToWords(net));
      const monthLabel = MONTH_NAMES[(data.month - 1 + 12) % 12] ?? data.month;

      const docDefinition: unknown = {
        pageSize: "A4",
        pageMargins: [40, 40, 40, 40],
        defaultStyle: {
          font: "Helvetica",
          fontSize: 10,
          color: COLOR.ink,
        },
        content: [
          /** Letterhead Section */
          {
            columns: [
              {
                width: "*",
                stack: [
                  {
                    text: "MKX Technologies Pvt. Ltd.",
                    fontSize: 17,
                    bold: true,
                    margin: [0, 0, 0, 5],
                  },
                  {
                    text: "129, Block A, Street Number 13,",
                    fontSize: 9.5,
                    color: COLOR.inkSoft,
                    margin: [0, 0, 0, 3],
                  },
                  {
                    text: "New Ashok Nagar, New Delhi, India - 110096",
                    fontSize: 9.5,
                    color: COLOR.inkSoft,
                  },
                ],
              },
              {
                width: 210,
                stack: [
                  {
                    text: "PAYSLIP",
                    fontSize: 13,
                    bold: true,
                    alignment: "right",
                    color: COLOR.inkSoft,
                    characterSpacing: 1.5,
                    margin: [0, 0, 0, 5],
                  },
                  {
                    text: `${monthLabel} ${data.year}`,
                    fontSize: 16,
                    bold: true,
                    alignment: "right",
                    margin: [0, 0, 0, 3],
                  },
                  {
                    columns: [
                      { text: "", width: "*" },
                      {
                        width: "auto",
                        table: {
                          widths: ["auto"],
                          body: [
                            [
                              {
                                text: (data.status || "Paid").toUpperCase(),
                                fontSize: 8,
                                bold: true,
                                color: COLOR.teal,
                                alignment: "center",
                                margin: [8, 3, 8, 3],
                              },
                            ],
                          ],
                        },
                        layout: "noBorders",
                        fillColor: COLOR.tealBg,
                      },
                    ],
                  },
                  {
                    text: `Pay date: ${data.payDate}`,
                    fontSize: 9,
                    alignment: "right",
                    color: COLOR.inkSoft,
                    margin: [0, 6, 0, 0],
                  },
                ],
              },
            ],
            margin: [0, 0, 0, 20],
          },
          {
            canvas: [
              { type: "line", x1: 0, y1: 0, x2: 515, y2: 0, lineWidth: 1, lineColor: COLOR.line },
            ],
            margin: [0, 0, 0, 20],
          },

          /** Employee Details Section */
          {
            columns: [
              {
                width: "52%",
                stack: [
                  {
                    text: "EMPLOYEE NAME",
                    fontSize: 7.5,
                    bold: true,
                    color: COLOR.muted,
                    characterSpacing: 0.4,
                    margin: [0, 0, 0, 3],
                  },
                  { text: data.employeeName, bold: true, fontSize: 11, margin: [0, 0, 0, 12] },
                  {
                    text: "DEPARTMENT",
                    fontSize: 7.5,
                    bold: true,
                    color: COLOR.muted,
                    characterSpacing: 0.4,
                    margin: [0, 0, 0, 3],
                  },
                  { text: data.department, bold: true, fontSize: 11 },
                ],
              },
              {
                width: "48%",
                stack: [
                  {
                    text: "EMPLOYEE ID",
                    fontSize: 7.5,
                    bold: true,
                    color: COLOR.muted,
                    characterSpacing: 0.4,
                    margin: [0, 0, 0, 3],
                  },
                  { text: data.employeeId, bold: true, fontSize: 11, margin: [0, 0, 0, 12] },
                  {
                    text: "DESIGNATION",
                    fontSize: 7.5,
                    bold: true,
                    color: COLOR.muted,
                    characterSpacing: 0.4,
                    margin: [0, 0, 0, 3],
                  },
                  { text: data.designation, bold: true, fontSize: 11 },
                ],
              },
            ],
            margin: [0, 0, 0, 22],
          },

          /** Earnings and Deductions Tables */
          {
            columns: [
              {
                width: "48%",
                ...earningsOrDeductionsTable(
                  "Earnings",
                  data.earnings,
                  gross,
                  COLOR.teal,
                  "No earnings",
                ),
              },
              { width: "4%", text: "" },
              {
                width: "48%",
                ...earningsOrDeductionsTable(
                  "Deductions",
                  data.deductions,
                  totalDeductions,
                  COLOR.brick,
                  "No deductions",
                ),
              },
            ],
            margin: [0, 0, 0, 22],
          },

          /** Perforation Line */
          {
            canvas: [
              {
                type: "line",
                x1: 0,
                y1: 0,
                x2: 515,
                y2: 0,
                lineWidth: 1,
                lineColor: COLOR.lineStrong,
                dash: { length: 3, space: 3 },
              },
            ],
            margin: [0, 0, 0, 0],
          },

          /** Net Pay Stub */
          {
            table: {
              widths: ["*", "auto"],
              body: [
                [
                  {
                    stack: [
                      {
                        text: "NET PAY DISBURSED",
                        fontSize: 8,
                        bold: true,
                        color: COLOR.gold,
                        characterSpacing: 0.4,
                        margin: [0, 0, 0, 4],
                      },
                      {
                        text: `Rupees ${netWords} only`,
                        fontSize: 8.5,
                        italics: true,
                        color: COLOR.gold,
                      },
                    ],
                    margin: [14, 16, 0, 16],
                    border: [false, false, false, false],
                  },
                  {
                    text: formatCurrency(net),
                    fontSize: 20,
                    bold: true,
                    color: COLOR.gold,
                    alignment: "right",
                    margin: [0, 20, 14, 16],
                    border: [false, false, false, false],
                  },
                ],
              ],
            },
            layout: "noBorders",
            fillColor: COLOR.goldBg,
            margin: [0, 0, 0, 24],
          },

          {
            text: "This is a computer generated document and does not require a physical signature.",
            alignment: "center",
            fontSize: 8,
            color: COLOR.muted,
          },
        ],
      };

      const doc = pdfmake.createPdf(docDefinition as unknown);
      doc
        .getBuffer()
        .then((buffer: Buffer) => resolve(buffer))
        .catch((err: Error) => reject(err));
    } catch (err) {
      reject(err);
    }
  });
};
