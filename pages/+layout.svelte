<script>
	import '@evidence-dev/tailwind/fonts.css';
	import '../app.css';
	import { EvidenceDefaultLayout } from '@evidence-dev/core-components';
	export let data;
	let builtwithevidence = false;

</script>

<style>
  :global(a[href="https://www.evidence.dev"]) {
    display: none !important;
  }
</style>
<EvidenceDefaultLayout {data} fullWidth = true title="Life Ambulance Network Reporting" builtWithEvidence neverShowQueries=true>
	<slot slot="content" />
</EvidenceDefaultLayout>