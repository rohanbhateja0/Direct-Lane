using Sitecore.Data.Items;
using System.Collections;

namespace CBRE.Feature.Pipelines.Scaffolding
{
  public class CreateNewSiteModel
  {
    public string SiteName { get; set; }

    public Item SiteLocation { get; set; }

    public bool CloneExistingSite { get; set; }

    public Item ExistingSite { get; set; }

    public ArrayList DefinitionItems { get; set; }

    public bool CreateSiteTheme { get; set; }

    public string ThemeName { get; set; }

    public Item[] ValidThemes { get; set; }

    public string Language { get; set; }

    public string HostName { get; set; }

    public string VirtualFolder { get; set; }

    public Item GridSetup { get; set; }

    public CreateNewSiteModel() => this.DefinitionItems = new ArrayList();
  }
}