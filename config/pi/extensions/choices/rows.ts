// The row list every screen is built from. Both the state machine and the
// renderer read it, so the numbering rules have exactly one definition: they
// drift the moment two modules derive them independently.

export interface Option {
  value: string;
  label: string;
  description?: string;
}

export interface Question {
  id: string;
  prompt: string;
  /** Short name for the tab bar. Defaults to Q1, Q2, Q3 by position. */
  label: string;
  options: Option[];
  multiple: boolean;
  allowOther: boolean;
}

export type Row =
  | { kind: "option"; index: number; option: Option; number: number }
  | { kind: "other"; number: number }
  | { kind: "next" }
  | { kind: "submit" }
  | { kind: "chat"; number: number }
  | { kind: "submit-answers"; number: number }
  | { kind: "cancel"; number: number };

export function buildRows(
  question: Question,
  isLastQuestion: boolean,
  isSingleQuestion: boolean,
): Row[] {
  const rows: Row[] = [];
  let number = 1;

  for (let index = 0; index < question.options.length; index++) {
    rows.push({
      kind: "option",
      index,
      option: question.options[index],
      number: number++,
    });
  }

  if (question.allowOther) {
    rows.push({ kind: "other", number: number++ });
  }

  // The terminal row exists to give Enter something to commit, which only
  // matters when Enter cannot already mean "choose this one". A single-select
  // single question answers on Enter and needs no row.
  if (!isSingleQuestion) {
    rows.push({ kind: "next" });
  } else if (question.multiple) {
    rows.push({ kind: "submit" });
  }

  // Always last, always below the bar: leaving the question is not one of the
  // ways to answer it.
  rows.push({ kind: "chat", number: number++ });

  return rows;
}
