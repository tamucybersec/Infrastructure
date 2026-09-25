const fs = require("fs");

const MARKER = "<!-- terraform-plan -->";
const MAX_LENGTH = 60000

function readPlan() {
	try {
		return fs.readFileSync(`${process.env.RUNNER_TEMP}/plan.txt`, "utf8");
	} catch {
		return "";
	}
}

function buildBody({ context, output, ok }) {
	const sha = context.payload.pull_request.head.sha.slice(0, 7);
	const trimmed =
		output.length > MAX_LENGTH
			? `... (truncated)\n${output.slice(-MAX_LENGTH)}`
			: output;

	return [
		MARKER,
		`### Terraform plan: ${ok ? "succeeded" : "FAILED"}`,
		`Commit ${sha}, planned against live state (no lock, nothing applied).`,
		"",
		"```",
		trimmed,
		"```",
	].join("\n");
}

module.exports = async ({ github, context }) => {
	const { owner, repo } = context.repo;
	const issue_number = context.issue.number;
	const body = buildBody({
		context,
		output: readPlan(),
		ok: process.env.PLAN_OUTCOME === "success",
	});

	const comments = await github.paginate(github.rest.issues.listComments, {
		owner,
		repo,
		issue_number,
	});
	const previous = comments.find((c) => c.body?.startsWith(MARKER));

	if (previous) {
		await github.rest.issues.updateComment({
			owner,
			repo,
			comment_id: previous.id,
			body,
		});
	} else {
		await github.rest.issues.createComment({
			owner,
			repo,
			issue_number,
			body,
		});
	}
};
